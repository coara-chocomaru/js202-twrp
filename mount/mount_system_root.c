#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define SYSTEM_ROOT "/system_root"
#define SYSTEM_LINK_DIR "/dev/block/twrp-by-name"
#define SYSTEM_LOG "/tmp/mount_system_root.log"

static void log_message(const char *message, int error_number, int truncate_file)
{
    int flags = O_WRONLY | O_CREAT | O_APPEND;
    int fd;
    char buffer[512];
    int length;

    if (truncate_file)
        flags |= O_TRUNC;
    fd = open(SYSTEM_LOG, flags, 0644);
    if (fd < 0)
        return;

    if (error_number != 0) {
        length = snprintf(buffer, sizeof(buffer), "%s: %s (%d)\n", message, strerror(error_number), error_number);
    } else {
        length = snprintf(buffer, sizeof(buffer), "%s\n", message);
    }

    if (length > 0)
        write(fd, buffer, (size_t)length);
    close(fd);
}

static int normalize_slot(const char *value, char suffix[3])
{
    if (value == NULL)
        return -1;
    if (strcmp(value, "a") == 0 || strcmp(value, "_a") == 0) {
        memcpy(suffix, "_a", 3);
        return 0;
    }
    if (strcmp(value, "b") == 0 || strcmp(value, "_b") == 0) {
        memcpy(suffix, "_b", 3);
        return 0;
    }
    return -1;
}

static int slot_from_cmdline(char suffix[3])
{
    FILE *file;
    char line[4096];
    char *save = NULL;
    char *token;
    char suffix_value[16] = "";
    char slot_value[16] = "";

    file = fopen("/proc/cmdline", "r");
    if (file == NULL)
        return -1;
    if (fgets(line, sizeof(line), file) == NULL) {
        fclose(file);
        return -1;
    }
    fclose(file);

    token = strtok_r(line, " \t\r\n", &save);
    while (token != NULL) {
        if (strncmp(token, "androidboot.slot_suffix=", 24) == 0)
            snprintf(suffix_value, sizeof(suffix_value), "%s", token + 24);
        else if (strncmp(token, "androidboot.slot=", 17) == 0)
            snprintf(slot_value, sizeof(slot_value), "%s", token + 17);
        token = strtok_r(NULL, " \t\r\n", &save);
    }

    if (suffix_value[0] != '\0')
        return normalize_slot(suffix_value, suffix);
    if (slot_value[0] != '\0')
        return normalize_slot(slot_value, suffix);
    return -1;
}

static int get_slot(int argc, char **argv, char suffix[3])
{
    if (argc > 2)
        return -1;
    if (argc == 2)
        return normalize_slot(argv[1], suffix);
    return slot_from_cmdline(suffix);
}

static int ensure_directory(const char *path)
{
    struct stat st;

    if (mkdir(path, 0755) == 0)
        return 0;
    if (errno != EEXIST)
        return -1;
    if (lstat(path, &st) == 0 && S_ISDIR(st.st_mode))
        return 0;
    errno = ENOTDIR;
    return -1;
}

static int ensure_symlink(const char *target, const char *link_path)
{
    struct stat st;
    char current[PATH_MAX];
    ssize_t length;

    if (lstat(link_path, &st) == 0) {
        if (S_ISLNK(st.st_mode)) {
            length = readlink(link_path, current, sizeof(current) - 1);
            if (length >= 0) {
                current[length] = '\0';
                if (strcmp(current, target) == 0)
                    return 0;
            }
            if (unlink(link_path) < 0)
                return -1;
        } else {
            errno = EEXIST;
            return -1;
        }
    }

    return symlink(target, link_path);
}

static int mounted_device_matches(const char *mount_point, const char *expected_device)
{
    FILE *file;
    char source[PATH_MAX];
    char target[PATH_MAX];
    char type[64];
    char options[256];
    int dump;
    int pass;
    struct stat expected_stat;
    struct stat source_stat;
    int result = 0;

    if (stat(expected_device, &expected_stat) < 0)
        return -1;
    if (!S_ISBLK(expected_stat.st_mode)) {
        errno = ENOTBLK;
        return -1;
    }

    file = fopen("/proc/mounts", "r");
    if (file == NULL)
        return -1;

    while (fscanf(file, "%4095s %4095s %63s %255s %d %d", source, target, type, options, &dump, &pass) == 6) {
        if (strcmp(target, mount_point) != 0)
            continue;

        if (stat(source, &source_stat) == 0 && S_ISBLK(source_stat.st_mode) &&
            source_stat.st_rdev == expected_stat.st_rdev) {
            result = 1;
        } else {
            errno = EXDEV;
            result = -1;
        }
        break;
    }

    fclose(file);
    return result;
}

static int mount_active_system(const char *device)
{
    int mounted = mounted_device_matches(SYSTEM_ROOT, device);

    if (mounted == 1)
        return 0;
    if (mounted < 0)
        return -1;

    if (mount(device, SYSTEM_ROOT, "ext4", MS_RDONLY | MS_NOATIME, NULL) == 0)
        return 0;

    if (errno == EBUSY) {
        mounted = mounted_device_matches(SYSTEM_ROOT, device);
        if (mounted == 1)
            return 0;
        if (mounted == 0)
            errno = EBUSY;
    }

    return -1;
}

int main(int argc, char **argv)
{
    char suffix[3] = "";
    char system_device[PATH_MAX];
    char system_a[PATH_MAX];
    char system_b[PATH_MAX];
    int attempt;
    struct timespec delay;

    log_message("mount_system_root start", 0, 1);

    if (get_slot(argc, argv, suffix) < 0) {
        log_message("active A/B slot is unavailable; refusing to select a partition", EINVAL, 0);
        return 1;
    }

    if (ensure_directory(SYSTEM_LINK_DIR) < 0) {
        log_message("cannot create TWRP A/B alias directory", errno, 0);
        return 1;
    }

    if (ensure_directory(SYSTEM_ROOT) < 0) {
        log_message("cannot create /system_root", errno, 0);
        return 1;
    }

    if (snprintf(system_a, sizeof(system_a), "%s/system_a", SYSTEM_LINK_DIR) >= (int)sizeof(system_a) ||
        snprintf(system_b, sizeof(system_b), "%s/system_b", SYSTEM_LINK_DIR) >= (int)sizeof(system_b)) {
        log_message("system alias path is too long", ENAMETOOLONG, 0);
        return 1;
    }

    if (snprintf(system_device, sizeof(system_device), "/dev/block/bootdevice/by-name/system%s", suffix) >= (int)sizeof(system_device)) {
        log_message("system device path is too long", ENAMETOOLONG, 0);
        return 1;
    }

    delay.tv_sec = 0;
    delay.tv_nsec = 100000000L;

    for (attempt = 0; attempt < 50; ++attempt) {
        if (access("/dev/block/bootdevice/by-name/system_a", F_OK) == 0 &&
            access("/dev/block/bootdevice/by-name/system_b", F_OK) == 0)
            break;
        nanosleep(&delay, NULL);
    }

    if (access("/dev/block/bootdevice/by-name/system_a", F_OK) != 0 ||
        access("/dev/block/bootdevice/by-name/system_b", F_OK) != 0) {
        log_message("both system slot block links are not available", ENOENT, 0);
        return 1;
    }

    if (ensure_symlink("/dev/block/bootdevice/by-name/system_a", system_a) < 0 ||
        ensure_symlink("/dev/block/bootdevice/by-name/system_b", system_b) < 0) {
        log_message("cannot create TWRP system slot aliases", errno, 0);
        return 1;
    }

    if (access(system_device, F_OK) != 0) {
        log_message("active system block device is not available", ENOENT, 0);
        return 1;
    }

    if (mount_active_system(system_device) < 0) {
        log_message("read-only ext4 mount of active system failed", errno, 0);
        return 1;
    }

    log_message("active system device verified on /system_root", 0, 0);
    return 0;
}

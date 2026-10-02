#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define SYSTEM_ROOT "/system_root"
#define SYSTEM_LINK "/dev/block/by-name/system"
#define LOG_FILE "/tmp/mount_system_root.log"

static const char *system_device(void)
{
    static const char *paths[] = {
        "/dev/block/bootdevice/by-name/system",
        "/dev/block/by-name/system",
        "/dev/block/bootdevice/by-name/system_a",
        "/dev/block/bootdevice/by-name/system_b",
        "/dev/block/by-name/system_a",
        "/dev/block/by-name/system_b",
        "/dev/block/mapper/system",
        "/dev/block/mapper/system_a",
        "/dev/block/mapper/system_b"
    };
    size_t i;

    for (i = 0; i < sizeof(paths) / sizeof(paths[0]); ++i) {
        if (access(paths[i], F_OK) == 0)
            return paths[i];
    }

    return NULL;
}

static int make_dir(const char *path)
{
    if (mkdir(path, 0755) == 0)
        return 0;

    if (errno == EEXIST)
        return 0;

    return -1;
}

static void write_log(const char *message, int error_number)
{
    int fd;
    char buffer[512];
    int length;

    fd = open(LOG_FILE, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0)
        return;

    if (error_number != 0) {
        length = snprintf(
            buffer,
            sizeof(buffer),
            "%s: %s (%d)\n",
            message,
            strerror(error_number),
            error_number
        );
    } else {
        length = snprintf(
            buffer,
            sizeof(buffer),
            "%s\n",
            message
        );
    }

    if (length > 0)
        write(fd, buffer, (size_t)length);

    close(fd);
}

static int prepare_system_link(const char *device)
{
    struct stat st;

    if (strcmp(device, SYSTEM_LINK) == 0)
        return 0;

    if (lstat(SYSTEM_LINK, &st) == 0) {
        if (S_ISLNK(st.st_mode) || S_ISREG(st.st_mode))
            unlink(SYSTEM_LINK);
        else
            return 0;
    }

    if (symlink(device, SYSTEM_LINK) == 0)
        return 0;

    if (errno == EEXIST)
        return 0;

    return -1;
}

static int mount_system(const char *device)
{
    int saved_errno;

    if (mount(device, SYSTEM_ROOT, "ext4", 0, NULL) == 0)
        return 0;

    if (errno == EBUSY)
        return 0;

    saved_errno = errno;

    if (mount(device, SYSTEM_ROOT, "ext4", MS_RDONLY, NULL) == 0) {
        mount(NULL, SYSTEM_ROOT, "ext4", MS_REMOUNT, NULL);
        return 0;
    }

    errno = saved_errno;
    return -1;
}

int main(void)
{
    const char *device = NULL;
    int i;

    write_log("mount_system_root start", 0);

    if (make_dir("/dev/block") < 0) {
        write_log("mkdir /dev/block failed", errno);
        return 1;
    }

    if (make_dir("/dev/block/by-name") < 0) {
        write_log("mkdir /dev/block/by-name failed", errno);
        return 1;
    }

    if (make_dir(SYSTEM_ROOT) < 0) {
        write_log("mkdir /system_root failed", errno);
        return 1;
    }

    umount2(SYSTEM_ROOT, MNT_DETACH);

    for (i = 0; i < 50; ++i) {
        device = system_device();

        if (device != NULL)
            break;

        usleep(100000);
    }

    if (device == NULL) {
        write_log("system block device not found", ENOENT);
        return 1;
    }

    if (prepare_system_link(device) < 0) {
        write_log("failed to create /dev/block/by-name/system", errno);
        return 1;
    }

    if (mount_system(device) < 0) {
        write_log("mount /system_root failed", errno);
        return 1;
    }

    if (mount(NULL, SYSTEM_ROOT, "ext4", MS_REMOUNT, NULL) < 0) {
        if (errno != EINVAL && errno != EROFS)
            write_log("rw remount failed", errno);
    }

    write_log("system mounted on /system_root", 0);

    return 0;
}

#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

/* Bit helpers for EVIOCGSW mask */
#ifndef BITS_PER_LONG
#define BITS_PER_LONG (sizeof(long) * 8)
#endif
#define NBITS(x) ((((x) + BITS_PER_LONG - 1) / BITS_PER_LONG))
#define OFF(x)   ((x) % BITS_PER_LONG)
#define LONGIDX(x) ((x) / BITS_PER_LONG)
#define TEST_BIT(bit, arr) ((arr[LONGIDX(bit)] >> OFF(bit)) & 1)

int main(int argc, char **argv) {
    if (argc < 2) {
        return 2; // require explicit device path
    }
    const char *dev = argv[1];

    int fd = open(dev, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 1;

    unsigned long sw_bits[NBITS(SW_MAX + 1)];
    memset(sw_bits, 0, sizeof(sw_bits));

    if (ioctl(fd, EVIOCGSW(sizeof(sw_bits)), sw_bits) < 0) {
        close(fd);
        return 1;
    }

    int value = TEST_BIT(SW_TABLET_MODE, sw_bits) ? 1 : 0;
    /* print ONLY 0 or 1 */
    if (value) write(STDOUT_FILENO, "1\n", 2);
    else       write(STDOUT_FILENO, "0\n", 2);

    close(fd);
    return 0;
}

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
    const char *dev = (argc > 1) ? argv[1] : "/dev/input/event8";

    int fd = open(dev, O_RDONLY);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    unsigned long sw_bits[NBITS(SW_MAX + 1)];
    memset(sw_bits, 0, sizeof(sw_bits));

    if (ioctl(fd, EVIOCGSW(sizeof(sw_bits)), sw_bits) < 0) {
        perror("ioctl(EVIOCGSW)");
        close(fd);
        return 1;
    }

    int value = TEST_BIT(SW_TABLET_MODE, sw_bits) ? 1 : 0;
    printf("tablet mode = %d\n", value);

    close(fd);
    return 0;
}

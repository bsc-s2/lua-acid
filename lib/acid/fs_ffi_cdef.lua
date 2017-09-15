local _M = {}


_M.cdef = [[
int errno;
struct timespec
{
    long int tv_sec;
    long int tv_nsec;
};
struct stat
{
    unsigned long int st_dev;
    unsigned long int st_ino;
    unsigned long int st_nlink;
    unsigned int st_mode;
    unsigned int st_uid;
    unsigned int st_gid;
    int __pad0;
    unsigned long int st_rdev;
    long int st_size;
    long int st_blksize;
    long int st_blocks;
    struct timespec st_atim;
    struct timespec st_mtim;
    struct timespec st_ctim;
    long int __unused[3];
};
struct dirent
{
    unsigned long int d_ino;
    long int d_off;
    unsigned short int d_reclen;
    unsigned char d_type;
    char d_name[256];
};

int __xstat(int ver, const char *path, struct stat *buf);
int access(const char *path, int amode);
void *opendir(const char *name);
int closedir(void *dirp);
struct dirent *readdir(void *dirp);
int mkdir(const char *path, unsigned int mode);
int chmod(const char *path, unsigned int mode);
int chown(const char *path, unsigned int owner, unsigned int group);
]]


return _M

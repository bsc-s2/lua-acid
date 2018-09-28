import utdocker

zk_name = 'zk_test'


if __name__ == '__main__':
    utdocker.remove_container(zk_name)

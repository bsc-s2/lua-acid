import utdocker

zk_tag = 'daocloud.io/zookeeper:3.4.10'
zk_name = 'zk_test'


if __name__ == '__main__':
    utdocker.pull_image(zk_tag)
    utdocker.create_network()
    utdocker.start_container(
        zk_name,
        zk_tag,
        env={
            "ZOO_MY_ID": 1,
            "ZOO_SERVERS": "server.1=0.0.0.0:2888:3888",
        },
        port_bindings={2181: 21811}
    )

<?php
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__, '/../../../.env');
$dotenv->load();
return [
    'backend' => [
        'frontName' => $_ENV['ADMIN_PATH']
    ],
    'remote_storage' => [
        'driver' => 'file'
    ],
    'queue' => [
        'amqp' => [
            'host' => 'rabbitmq',
            'port' => '5672',
            'user' => 'rabbitmq_'. $_ENV['OWNER'],
            'password' => $_ENV['RABBITMQ_PASSWORD'],
            'virtualhost' => '/'
        ],
        'consumers_wait_for_messages' => 0
    ],
    'indexer' => [
        'batch_size' => [
            'cataloginventory_stock' => [
                'simple' => 650
            ],
            'catalog_category_product' => 1000,
            'catalogsearch_fulltext' => [
                'partial_reindex' => 650,
                'mysql_get' => 850,
                'elastic_save' => 1000
            ],
            'catalog_product_price' => [
                'simple' => 650,
                'default' => 850,
                'configurable' => 1000
            ],
            'catalogpermissions_category' => 1000,
            'inventory' => [
                'simple' => 650,
                'default' => 850,
                'configurable' => 1000
            ]
        ]
    ],
    'cron_consumers_runner' => [
    'cron_run' => true,
    'max_messages' => 5,
    'single_thread' => true,
    'consumers_wait_for_messages' => 0,
    'consumers' => [
		'product_action_attribute.update',
		'product_action_attribute.website.update',
		'exportProcessor',
		'codegeneratorProcessor',
		'sales.rule.update.coupon.usage',
		'sales.rule.quote.trigger.recollect',
		'product_alert'
         ]
    ],
    'crypt' => [
        'key' => $_ENV['CRYPT_KEY']
    ],
    'db' => [
        'table_prefix' => '',
        'connection' => [
            'default' => [
                'host' => 'mariadb',
                'dbname' => $_ENV['DATABASE_NAME'],
                'username' => $_ENV['DATABASE_USER'],
                'password' => $_ENV['DATABASE_PASSWORD'],
                'model' => 'mysql4',
                'engine' => 'innodb',
                'initStatements' => 'SET NAMES utf8;',
                'active' => '1',
                'driver_options' => [
                    1014 => false
                ]
            ]
        ]
    ],
    'resource' => [
        'default_setup' => [
            'connection' => 'default'
        ]
    ],
    'MAGE_MODE' => $_ENV['MODE'],
    'session' => [
        'save' => 'redis',
        'redis' => [
            'host' => 'session-'.$_ENV['OWNER'],
            'port' => $_ENV['REDIS_SESSION_PORT'],
            'password' => $_ENV['REDIS_PASSWORD'],
            'timeout' => '2.5',
            'persistent_identifier' => $_ENV['OWNER'].'_sess',
            'database' => '0',
            'compression_threshold' => '2048',
            'compression_library' => 'lz4',
            'log_level' => '3',
            'max_concurrency' => '6',
            'break_after_frontend' => '5',
            'break_after_adminhtml' => '30',
            'first_lifetime' => '600',
            'bot_first_lifetime' => '60',
            'bot_lifetime' => '7200',
            'disable_locking' => '0',
            'min_lifetime' => '60',
            'max_lifetime' => '2592000',
            'sentinel_master' => '',
            'sentinel_servers' => '',
            'sentinel_connect_retries' => '5',
            'sentinel_verify_master' => '0'
        ]
    ],
    'cache' => [
        'graphql' => [
            'id_salt' => $_ENV['GRAPHQL_ID_SALT']
        ],
        'frontend' => [
            'default' => [
                'id_prefix' => $_ENV['OWNER'].'_',
                'backend' => 'Magento\\Framework\\Cache\\Backend\\Redis',
                'backend_options' => [
                    'server' => 'cache-'.$_ENV['OWNER'],
                    'database' => '0',
                    'persistent' => $_ENV['OWNER'].'_cache',
                    'port' => $_ENV['REDIS_CACHE_PORT'],
                    'password' => $_ENV['REDIS_PASSWORD'],
                    'compress_data' => '1',
                    'compression_lib' => 'l4z',
                    'preload_keys' => [
                                        $_ENV['OWNER'].'_EAV_ENTITY_TYPES',
                                        $_ENV['OWNER'].'_GLOBAL_PLUGIN_LIST',
                                        $_ENV['OWNER'].'_DB_IS_UP_TO_DATE',
                                        $_ENV['OWNER'].'_SYSTEM_DEFAULT',
                          ]
		]
	]
    ],
        'allow_parallel_generation' => false
    ],
    'lock' => [
        'provider' => 'db'
    ],
    'directories' => [
        'document_root_is_pub' => true
    ],
    'http_cache_hosts' => [
        [
            'host' => 'varnish',
            'port' => '8081'
        ]
    ],
    'cache_types' => [
        'config' => 1,
        'layout' => 1,
        'block_html' => 1,
        'collections' => 1,
        'reflection' => 1,
        'db_ddl' => 1,
        'compiled_config' => 1,
        'eav' => 1,
        'customer_notification' => 1,
        'full_page' => 1,
        'config_integration' => 1,
        'config_integration_api' => 1,
        'translate' => 1,
        'config_webservice' => 1
    ],
    'downloadable_domains' => [
        $_ENV['DOMAIN']
    ],
    'system' => [
        'default' => [
            'catalog' => [
                'search' => [
                    'engine' => 'elasticsearch7',
                    'elasticsearch7_server_hostname' => 'elasticsearch',
                    'elasticsearch7_enable_auth' => '1',
                    'elasticsearch7_server_port' => '9200',
                    'elasticsearch7_index_prefix' => 'indexer_'.$_ENV['OWNER'],
                    'elasticsearch7_username' => 'indexer_'.$_ENV['OWNER'],
                    'elasticsearch7_password' => $_ENV['INDEXER_PASSWORD']
                ]
            ]
        ]
    ],
    'install' => [
        'date' => 'Thu, 11 Aug 2022 10:47:18 +0000'
    ]
];

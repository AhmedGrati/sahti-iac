resource "aws_ecs_cluster" "ecs-cluster" {
  name = "DevOpsLabCluster"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_cloudwatch_log_group" "api_logs" {
  name = "/ecs/api"
}
resource "aws_cloudwatch_log_group" "postgres_logs" {
  name = "/ecs/postgres"
}
resource "aws_cloudwatch_log_group" "redis_logs" {
  name = "/ecs/redis"
}





resource "aws_security_group" "egress_all" {
  name        = "egress-all"
  description = "Allow all outbound traffic"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress_api" {
  name        = "ingress-api"
  description = "Allow ingress to API"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress_postgres" {
  name        = "ingress-postgres"
  description = "Allow ingress to Postgres"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress_redis" {
  name        = "ingress-redis"
  description = "Allow ingress to Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_ecs_task_definition" "postgres-task-definiton" {
  family = "postgres"
  container_definitions = jsonencode(
    [
      {
        name : "postgres",
        image : "registry.hub.docker.com/library/postgres:12",
        environment : [
          { "name" : "POSTGRES_PASSWORD", "value" : "${var.postgres_password}" },
          { "name" : "POSTGRES_DB", "value" : "sahti" },
          { "name" : "POSTGRES_USER", "value" : "${var.postgres_username}" }
        ]
        portMappings : [
          {
            containerPort : 5432,
            hostPort : 5432
          }
        ],
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-region : "us-east-1",
            awslogs-group : "/ecs/postgres",
            awslogs-stream-prefix : "ecs"
          }
        }
      }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_service" "postgres-service" {
  name            = "postgres-service"                                  # Naming our first service
  cluster         = aws_ecs_cluster.ecs-cluster.id                      # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.postgres-task-definiton.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 1

  service_registries {
    registry_arn   = aws_service_discovery_service.postgres-svc-discovery.arn
    container_name = "postgres"
  }


  network_configuration {
    subnets          = [var.default_subnet_a_id, var.default_subnet_b_id, var.default_subnet_c_id]
    assign_public_ip = true

    security_groups = [aws_security_group.egress_all.id, aws_security_group.ingress_postgres.id]
  }
}

resource "aws_ecs_task_definition" "redis-task-definition" {
  family = "redis"
  container_definitions = jsonencode(
    [
      {
        name : "redis",
        image : "registry.hub.docker.com/library/redis",
        portMappings : [
          {
            containerPort : 6379,
            hostPort : 6379
          }
        ],
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-region : "us-east-1",
            awslogs-group : "/ecs/redis",
            awslogs-stream-prefix : "ecs"
          }
        }
      }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_service" "redis-service" {
  name            = "redis-service"                                   # Naming our first service
  cluster         = aws_ecs_cluster.ecs-cluster.id                    # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.redis-task-definition.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 1

  service_registries {
    registry_arn   = aws_service_discovery_service.redis-svc-discovery.arn
    container_name = "redis"
  }

  network_configuration {
    subnets          = [var.default_subnet_a_id, var.default_subnet_b_id, var.default_subnet_c_id]
    assign_public_ip = true

    security_groups = [aws_security_group.egress_all.id, aws_security_group.ingress_redis.id]
  }
}

resource "aws_service_discovery_private_dns_namespace" "svc-discovery" {
  name        = "local"
  description = "Service Discovery for containers communications"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "postgres-svc-discovery" {
  name = "postgres"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.svc-discovery.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_service_discovery_service" "redis-svc-discovery" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.svc-discovery.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "sahti-backend-task-definiton" {
  family = "sahti-backend"
  container_definitions = jsonencode(
    [
      {
        name : "sahti-backend",
        image : "registry.hub.docker.com/ahmedgrati/sahti",
        environment : [
          { "name" : "POSTGRES_PASSWORD", "value" : "${var.postgres_password}" },
          { "name" : "POSTGRES_DB", "value" : "${var.postgres_db}" },
          { "name" : "POSTGRES_USER", "value" : "${var.postgres_username}" },
          { "name" : "HOST", "value" : "postgres.local" },
          { "name" : "REDIS_HOST", "value" : "redis.local" },
          { "name" : "DB_PORT", "value" : "${var.postgres_port}" },
          { "name" : "REDIS_PORT", "value" : "${var.redis_port}" },
          { "name" : "PORT", "value" : "${var.api_port}" },
          { "name" : "JWT_VERIFICATION_TOKEN_SECRET", "value" : "${var.jwt_verif_token_secret}" },
          { "name" : "JWT_VERIFICATION_TOKEN_EXPIRATION_TIME", "value" : "${var.jwt_verif_token_expir_time}" },
          { "name" : "JWT_LOGIN_TOKEN_SECRET", "value" : "${var.jwt_login_token_secret}" },
          { "name" : "JWT_LOGIN_TOKEN_EXPIRATION_TIME", "value" : "${var.jwt_login_token_expir_time}" },
          { "name" : "JWT_REFRESH_TOKEN_SECRET", "value" : "${var.jwt_refresh_token_secret}" },
          { "name" : "JWT_REFRESH_TOKEN_EXPIRATION_TIME", "value" : "${var.jwt_refresh_token_expir_time}" },
          { "name" : "JWT_RESET_TOKEN_SECRET", "value" : "${var.jwt_reset_token_secret}" },
        ]
        portMappings : [
          {
            containerPort : 4000,
            hostPort : 4000
          }
        ],
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-region : "us-east-1",
            awslogs-group : "/ecs/api",
            awslogs-stream-prefix : "ecs"
          }
        }
      }
  ])
  depends_on = [
    aws_ecs_task_definition.postgres-task-definiton,
    aws_ecs_task_definition.redis-task-definition
  ]
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}
resource "aws_ecs_service" "sahti-backend-service" {
  name            = "sahti-backend-service"                                  # Naming our first service
  cluster         = aws_ecs_cluster.ecs-cluster.id                           # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.sahti-backend-task-definiton.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 1

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name = "sahti-backend"
    container_port = 4000
  }
  network_configuration {
    subnets          = [var.default_subnet_a_id, var.default_subnet_b_id, var.default_subnet_c_id]
    assign_public_ip = true
    

    security_groups = [aws_security_group.egress_all.id, aws_security_group.ingress_api.id]
  }
}

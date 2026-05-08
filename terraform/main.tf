resource "aws_ecr_repository" "app_repo" {
  name = "devops-app-repo"
}
resource "aws_ecs_cluster" "main" {
  name = "devops-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_task_definition" "app_task" {
  family                   = "devops-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  container_definitions = jsonencode([
    {
      name      = "devops-app"
      image     = "149057603822.dkr.ecr.us-east-1.amazonaws.com/devops-app-repo:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "devops-app-service"

  cluster         = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.app_task.arn

  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0a01ab852f7ec33af"]

    assign_public_ip = true

    security_groups  = ["sg-0952704b1dcc6cfcc"]
  }
}
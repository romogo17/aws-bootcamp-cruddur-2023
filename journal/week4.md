# Week 4 — Postgres and RDS

- [Week 4 — Postgres and RDS](#week-4--postgres-and-rds)
  - [Required Homework](#required-homework)
    - [Create Congito Trigger to insert user into database](#create-congito-trigger-to-insert-user-into-database)
  - [Homework Challenges](#homework-challenges)
    - [Database design improvement](#database-design-improvement)
    - [Create the RDS instance using Terraform](#create-the-rds-instance-using-terraform)

## Required Homework
> **Note**: The following items are not documented here but already done through the student portal
> - I attended the Week 4 live stream, in which we created the RDS instance and a couple bash scripts
> - Watched the Security Considerations video and did the respective quiz



### Create Congito Trigger to insert user into database

I created the Cognito trigger fully through automation, using a combination of Terraform (since I had already created my User Pool through Terraform) and AWS SAM

The Terraform updates are located here [`infrastructure/02-app/cognito.tf`](../infrastructure/02-app/cognito.tf), in a nutshell I just had to:
* Update the user pool configuration to add the `lambda_config`
  ![](./assets/week4/lambda-trigger.png)
* Create a `aws_lambda_permission` resource so that the `cognito-idp.amazonaws.com` principal has permissions to invoke our lambda. This is done automatically when we use the console, but we must do it explicitly when using automation.
  ![](./assets/week4/lambda-resource-based-policy.png)

The AWS SAM template is located here [`infrastructure/03-lambdas/template.yaml`](../infrastructure/03-lambdas/template.yaml), a couple highlights are that:
* I'm using the [`aws_lambda_powertools`](https://awslabs.github.io/aws-lambda-powertools-python/) for logging
* I'm leveraging my `sam build` to bundle the `psycopg2-binary` package instead of using an untrusted layer

After both of these, the post confirmation user trigger worked as expected and I could see the rows being inserted in the `users` table.
```
cruddur=> select * from users;
                 uuid                 | display_name |  handle  |       email        |           cognito_user_id            |         created_at
--------------------------------------+--------------+----------+--------------------+--------------------------------------+----------------------------
 6fc02b94-6834-455b-b301-e88c444ffdfc | Roberto Mora | romogo17 | romogo17@gmail.com | dd85735c-5e1a-417a-8952-8a834d4c991a | 2023-03-16 03:13:55.639628
(1 row)

```

## Homework Challenges

### Database design improvement

I added a small improvement to the activities schema, which is a foreign key to the users dable

```diff
  CREATE TABLE public.activities (
    uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_uuid UUID NOT NULL,
    message text NOT NULL,
    replies_count integer DEFAULT 0,
    reposts_count integer DEFAULT 0,
    likes_count integer DEFAULT 0,
    reply_to_activity_uuid integer,
    expires_at TIMESTAMP,
    created_at TIMESTAMP default current_timestamp NOT NULL,
+   CONSTRAINT fk_user_uuid
+       FOREIGN KEY(user_uuid)
+       REFERENCES users(uuid)
  );
```

### Create the RDS instance using Terraform
I followed along during the livestream, however, as en extra challenge, I created my final RDS instance through Terraform

The code can be found under [`infrastructure/02-app/rds.tf`](../infrastructure/02-app/rds.tf)

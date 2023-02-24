# Week 1 — App Containerization

- [Week 1 — App Containerization](#week-1--app-containerization)
  - [Required Homework](#required-homework)
    - [Containerize Applications](#containerize-applications)
      - [BACKEND](#backend)
      - [FRONTEND](#frontend)
      - [DOCKER COMPOSE](#docker-compose)
    - [OpenAPI Documentation for notifications endpoint](#openapi-documentation-for-notifications-endpoint)
    - [Flask backend endpoint for notifications](#flask-backend-endpoint-for-notifications)
    - [React page for notifications](#react-page-for-notifications)
    - [DynamoDB Local container](#dynamodb-local-container)
    - [PostgreSQL container](#postgresql-container)
  - [Homework Challenges](#homework-challenges)

## Required Homework

> **Note**: The following items are not documented here but already done through the student portal
> - Watch How to ask for technical help video
> - Watch Grading homework summaries
> - I attended the Week 1 live stream
> - I did commit my code on monday once I used my laptop again and realized I hadn't commited it
> - Watched both the Spending and Container Security Considerations and did the respective quizzes
>

### Containerize Applications
- Created the `Dockerfile` for both the frontend and backend apps
- Created the `docker-compose.yml` file

#### BACKEND
```sh
# build
docker build -t  backend-flask ./backend-flask

# run
docker run --rm -p 4567:4567 -d -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask
```
![](./assets/week1/backend-container.png)


#### FRONTEND
```sh
# build
docker build -t frontend-react-js ./frontend-react-js

# run
docker run --rm -p 3000:3000 -d frontend-react-js
```

![](./assets/week1/frontend-container.png)


#### DOCKER COMPOSE

In our `docker-compose.yml` file, we're mounting directories with the local contents of the repos (`volumes`). If we don't have the required dependencies installed, our app won't run properly
```
cd backend-flask
pip3 install -r requirements.txt

cd frontend-react-js
npm install
```
Then,

```sh
docker compose up
```

![](./assets/week1/docker-compose.png)

### OpenAPI Documentation for notifications endpoint
Completed the documentation of the notifications endpoint following the OpenAPI specification.

![](./assets/week1/openapi.png)

I'm glad we're using this! I had ussed swagger back then but hadn't played around with it in some time 😄

### Flask backend endpoint for notifications

Created the Flask backend endpoint for notifications
![](./assets/week1/backend-notifications.png)

### React page for notifications

Created the React frontend page endpoint for notifications
![](./assets/week1/frontend-notifications.png)

Which, when accessed, looks like this:
![](./assets/week1/notifications-browser.png)

### DynamoDB Local container
Included the `dynamodb-local` container to the Docker Compose and tested it out

![](./assets/week1/dynamodb-local.png)

I really liked that we get to play around with DynamoDB local. This is something I've been meaning to do for some time but didn't have the excuse to do it 🚀


### PostgreSQL container
Included the `postgres` container to the Docker Compose and tested it out

![](./assets/week1/postgresql.png)

## Homework Challenges
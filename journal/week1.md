# Week 1 — App Containerization

- [Week 1 — App Containerization](#week-1--app-containerization)
  - [Required Homework](#required-homework)
    - [Containerize Applications](#containerize-applications)
      - [BACKEND](#backend)
      - [FRONTEND](#frontend)
      - [DOCKER COMPOSE](#docker-compose)
  - [Homework Challenges](#homework-challenges)

## Required Homework

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

## Homework Challenges
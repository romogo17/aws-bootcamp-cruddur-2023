FROM 921979471021.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster
LABEL org.opencontainers.image.authors="Roberto.Mora@experian.com"
LABEL org.opencontainers.image.source="https://github.com/romogo17/aws-bootcamp-cruddur-2023.git"

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt \
    && apt-get update && apt-get install curl -y

COPY . .

ENV FLASK_DEBUG=1

EXPOSE ${PORT}
# CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]

ENTRYPOINT [ "/bin/sh" ]
CMD [ "docker-cmd.sh" ]
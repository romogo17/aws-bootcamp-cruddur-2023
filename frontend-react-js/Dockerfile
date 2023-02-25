FROM node:16.18
LABEL org.opencontainers.image.authors="Roberto.Mora@experian.com"
LABEL org.opencontainers.image.source="https://github.com/romogo17/aws-bootcamp-cruddur-2023.git"

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]
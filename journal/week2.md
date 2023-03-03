# Week 2 — Distributed Tracing

- [Week 2 — Distributed Tracing](#week-2--distributed-tracing)
  - [Required Homework](#required-homework)
    - [Instrument Honeycomb with OTEL](#instrument-honeycomb-with-otel)
    - [Instrument AWS X-Ray](#instrument-aws-x-ray)
    - [Configured a custom logger with CloudWatch Logs](#configured-a-custom-logger-with-cloudwatch-logs)
    - [Integrate an error and capture an error](#integrate-an-error-and-capture-an-error)
  - [Homework Challenges](#homework-challenges)


## Required Homework
> **Note**: The following items are not documented here but already done through the student portal
> - I attended the Week 2 live stream
> - Watched both the Spending and Container Security Considerations and did the respective quizzes

### Instrument Honeycomb with OTEL
The Honeycomb instrumentation was done during the live session. For that one, we used the Open Telemetry libraries.
![](./assets/week2/honeycomb-query.png)
![](./assets/week2/honeycomb-metadata.png)

I want to point out, having done both Honeycomb and X-Ray at the time of writing, instrumenting for Honeycomb was much more intuitive and easy!

### Instrument AWS X-Ray
Completed the instrumentation with AWS X-Ray. The AWS resources we needed to create for it were created using Terraform.
The code for that is under [`./infrastructure/02-app`](./../infrastructure/02-app/).

I faced some issues instrumenting the `/api/activities/@handle` endpoint. For some reason the traces for it didn't show up at all in the console.
I ended up needing to start the segment like this and just rely on subsegments for the rest
```
try:
  xray_recorder.current_segment()
except:
  xray_recorder.begin_segment('user.activities')
```
After some troubleshooting I managed to get it working
![](./assets/week2/xray-query.png)

When opening the trace I could also see the custom metadata added
![](./assets/week2/xray-metadata.png)

### Configured a custom logger with CloudWatch Logs

Following the instructions provided in the video, configured custom logger to send logs to CloudWatch Logs

![](./assets/week2/cloudwatch-logs-group.png)
![](./assets/week2/cloudwatch-logs-stream.png)

This was done with this commit ([`a055c35`](https://github.com/romogo17/aws-bootcamp-cruddur-2023/commit/a055c350a04667b78362fcfd016b77df25b2ef3d)) but later on commented to save on costs

### Integrate an error and capture an error

I found the integration with Rollbar as easy as the one with Honeycomb. Very intuitive :smile:

![](./assets/week2/rollbar-error.png)

## Homework Challenges
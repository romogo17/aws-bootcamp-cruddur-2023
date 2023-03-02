# Week 2 — Distributed Tracing

- [Week 2 — Distributed Tracing](#week-2--distributed-tracing)
  - [Required Homework](#required-homework)
    - [Instrument Honeycomb with OTEL](#instrument-honeycomb-with-otel)
    - [Instrument AWS X-Ray](#instrument-aws-x-ray)
  - [Homework Challenges](#homework-challenges)


## Required Homework
> **Note**: The following items are not documented here but already done through the student portal
> - I attended the Week 2 live stream
> - Watched both the Spending and Container Security Considerations and did the respective quizzes

### Instrument Honeycomb with OTEL
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

## Homework Challenges
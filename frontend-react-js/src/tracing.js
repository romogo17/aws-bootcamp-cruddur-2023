import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
// import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { ZoneContextManager } from '@opentelemetry/context-zone';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions'

import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';
import { XMLHttpRequestInstrumentation } from '@opentelemetry/instrumentation-xml-http-request';

console.log(`here2 ===> ${process.env.REACT_APP_BACKEND_URL}`)
console.log(`here1 ===> ${process.env.WHATS_GOING_ON_W_THIS}`)

const exporter = new OTLPTraceExporter({
    // url: process.env.OTEL_COLLECTOR
    url: "https://4318-romogo17-awsbootcampcru-0fj0ipe2vl8.ws-us89.gitpod.io/v1/traces"
});
const provider = new WebTracerProvider({
    resource: new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: 'cruddur-frontend-react',
    }),
});
provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register({
    contextManager: new ZoneContextManager()
});

registerInstrumentations({
    instrumentations: [
    //   new XMLHttpRequestInstrumentation({
    //     propagateTraceHeaderCorsUrls: [
    //        /.+/g, //Regex to match your backend urls. This should be updated.
    //     ]
    //   }),
      new FetchInstrumentation({
        propagateTraceHeaderCorsUrls: [
           /.+/g, //Regex to match your backend urls. This should be updated.
        ]
      }),
    ],
  });

// registerInstrumentations({
//     instrumentations: [
//         getWebAutoInstrumentations({
//             // load custom configuration for xml-http-request instrumentation
//             '@opentelemetry/instrumentation-xml-http-request': {
//                 propagateTraceHeaderCorsUrls: [
//                     /.+/g,
//                     process.env.REACT_APP_BACKEND_URL
//                 ],
//             },
//             // load custom configuration for fetch instrumentation
//             '@opentelemetry/instrumentation-fetch': {
//                 propagateTraceHeaderCorsUrls: [
//                     /.+/g,
//                     process.env.REACT_APP_BACKEND_URL
//                 ],
//             },
//         }),
//     ],
// });
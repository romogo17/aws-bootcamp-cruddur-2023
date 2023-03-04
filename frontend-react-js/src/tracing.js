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

console.log(`Using OTEL Collector URL = ${process.env.REACT_APP_OTEL_COLLECTOR_URL}`)

const exporter = new OTLPTraceExporter({
    url: `${process.env.REACT_APP_OTEL_COLLECTOR_URL}/v1/traces`
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
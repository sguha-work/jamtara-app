import type { APIGatewayProxyEvent, APIGatewayProxyResult, Handler } from "aws-lambda"
import type { FromSchema } from "json-schema-to-ts";

type ValidatedAPIGatewayProxyEvent<S> = Omit<APIGatewayProxyEvent, 'body'> & { body: FromSchema<S> }
export type ValidatedEventAPIGatewayProxyEvent<S> = Handler<ValidatedAPIGatewayProxyEvent<S>, APIGatewayProxyResult>

export const formatJSONResponse = (response: Record<string, unknown>, statusCode?: number) => {
  console.log("Format response");
  return {
    // statusCode: 200,
    // body: JSON.stringify(response)
    "statusCode": statusCode ? statusCode : 200,
    "body": JSON.stringify(response),
    "headers": {
      "Content-Type": "application/json"
    }
  }
}

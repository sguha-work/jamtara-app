package main

import (
	"bytes"
	"context"
	"encoding/json"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"fmt"

	model "github.com/server/go/db/models"
)

// var (
// 	addr = flag.String("addr", "postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636", "the address of the database")
// )

// Response is of type APIGatewayProxyResponse since we're leveraging the
// AWS Lambda Proxy Request functionality (default behavior)
//
// https://serverless.com/framework/docs/providers/aws/events/apigateway/#lambda-proxy-integration
type Response events.APIGatewayProxyResponse

// Handler is our lambda handler invoked by the `lambda.Start` function call
func Handler(ctx context.Context, request events.APIGatewayProxyRequest) (Response, error) {
	fmt.Println("Handler-->Hello", request.PathParameters)
	var qParams = request.PathParameters
	// var qParams [] interface {}
	// if request.QueryStringParameters["sub_division"] != "" {
	// 	qParams = append(qParams, map[string]string{S})
	// }

	// db, err := gorm.Open(postgres.Open(os.Getenv("DATABASE_URL")), &gorm.Config{})
	db, err := gorm.Open(postgres.Open("postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636"))

	if err != nil {
		log.Fatal(err)
	}

	// db.AutoMigrate(&Consumer{})

	// var consumers []*model.Consumer
	var circles []*model.Circles
	// db.Where(qParams).Find(&consumers)
	db.Preload("Divisions").Where(qParams).Find(&circles)
	fmt.Println(circles)

	var buf bytes.Buffer

	body, err := json.Marshal(map[string]interface{}{
		"message": "Go Serverless v1.0! Your function executed successfully!!!",
		"circles": circles,
		"qParams": qParams,
	})
	if err != nil {
		return Response{StatusCode: 404}, err
	}
	json.HTMLEscape(&buf, body)

	resp := Response{
		StatusCode:      200,
		IsBase64Encoded: false,
		Body:            buf.String(),
		Headers: map[string]string{
			"Content-Type":           "application/json",
			"X-MyCompany-Func-Reply": "hello-handler",
		},
	}

	return resp, nil
}

func main() {
	lambda.Start(Handler)
}

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

type Response events.APIGatewayProxyResponse

func Handler(ctx context.Context, request events.APIGatewayProxyRequest) (Response, error) {
	db, err := gorm.Open(postgres.Open("postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636"))

	if err != nil {
		log.Fatal(err)
	}

	var divisions []*model.Divisions

	db.Preload("Sub_divisions").Find(&divisions)
	fmt.Println(divisions)

	var buf bytes.Buffer

	body, err := json.Marshal(map[string]interface{}{
		"divisions": divisions,
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

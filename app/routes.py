from app import app

from datetime import datetime
from flask import Flask, render_template, request
import boto3

client = boto3.client("dynamodb", region_name="eu-west-1")
dynamoTableName = "datesTable"

@app.route("/", methods=["GET", "POST"])
def index():
  date = datetime.utcnow()
  pretty_date = date.strftime("%B %d %Y %H:%M")
  if request.method == "POST":
    # here the "date" key must match the partition key selected when provisioning the dynamodb
    client.put_item(TableName=dynamoTableName, Item={"date": { "S": pretty_date}})

  return render_template("index.html")


@app.route("/collection", methods=["GET"])
def collection():
  dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
  table = dynamodb.Table("datesTable")

  response = table.scan()
  data = response["Items"]

  while "LastEvaluatedKey" in response:
      response = table.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
      data.extend(response["Items"])
  return render_template("collection.html", data=data)
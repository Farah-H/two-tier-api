from datetime import datetime
from flask import Flask, render_template, request
import boto3


boto3.setup_default_session(profile_name="pollinate")
client = boto3.client("dynamodb", region_name="eu-west-1")
dynamoTableName = "datesTable"
app = Flask(__name__)

@app.route("/", methods=["GET", "POST"])
def index():
  date = datetime.utcnow()
  pretty_date = date.strftime("%B %d %Y %H:%M")
  if request.method == "POST":
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


if __name__ == "__main__":
  app.run(host="0.0.0.0", port=5000, debug=True)

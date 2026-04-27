import os
import urllib.parse
import boto3

sns = boto3.client("sns")

def lambda_handler(event, context):
    record = event["Records"][0]
    evento = record["eventName"]  # ex: ObjectCreated:Put, ObjectRemoved:Delete
    bucket = record["s3"]["bucket"]["name"]
    chave  = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

    # Exclusão não tem tamanho
    if "ObjectRemoved" in evento:
        acao     = "excluído"
        detalhes = ""
    else:
        acao     = "adicionado"
        tamanho  = record["s3"]["object"].get("size", 0)
        detalhes = f"\nTamanho: {tamanho} bytes"

    mensagem = (
        f"Arquivo {acao} no S3!\n\n"
        f"Bucket: {bucket}\n"
        f"Arquivo: {chave}"
        f"{detalhes}"
    )

    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject=f"[S3] Arquivo {acao}: {chave}",
        Message=mensagem,
    )

    return {"statusCode": 200}
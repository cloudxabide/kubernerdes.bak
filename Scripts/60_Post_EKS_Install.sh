kubectl get secret -n eksa-packages aws-secret -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}'  | base64 --decode

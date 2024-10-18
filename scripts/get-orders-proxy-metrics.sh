kubectl exec -it deploy/graphql -n ecommerce -c istio-proxy \
-- curl localhost:15000/clusters | grep orders
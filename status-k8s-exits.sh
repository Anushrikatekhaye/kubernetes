for r in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
  echo "=== $r ==="
  aws eks list-clusters --region "$r" --query "clusters" --output text
done

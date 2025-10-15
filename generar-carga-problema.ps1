for ($i = 1; $i -le 6; $i++) {
    $podName = "load-generator-$i"
    Write-Host "Creando $podName..."
    # Ejecuta el pod con un bucle infinito
    kubectl run -n escalabilidad-lab $podName `
      --image=busybox:1.28 `
      --restart=Never `
      -- /bin/sh -c 'while true; do wget -q -O- http://app-web-service; done'
}
# SOLUCIÓN PARA DOCKER DESKTOP - Metrics Server con SSL deshabilitado

# PASO 1: Primero, eliminar la instalación anterior (si existe)
Write-Host "Eliminando instalación anterior..." -ForegroundColor Yellow
kubectl delete deployment metrics-server -n kube-system --ignore-not-found

# PASO 2: Esperar un poco
Start-Sleep -Seconds 5

# PASO 3: Crear el YAML personalizado para Docker Desktop
Write-Host "Creando configuración personalizada..." -ForegroundColor Green

$metricsServerYaml = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - nodes/metrics
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: deployment.apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      name: metrics-server
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server/metrics-server:v0.6.4
        imagePullPolicy: IfNotPresent
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
          - --kubelet-insecure-tls
          - --logtostderr
          - --v=2
        ports:
        - name: https
          containerPort: 4443
          protocol: TCP
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - name: tmp-vol
          mountPath: /tmp
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      volumes:
      - name: tmp-vol
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    k8s-app: metrics-server
---
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io
spec:
  service:
    name: metrics-server
    namespace: kube-system
  group: metrics.k8s.io
  version: v1beta1
  insecureSkipTLSVerify: true
  groupPriorityMinimum: 100
  versionPriority: 100
"@

# PASO 4: Guardar el YAML en un archivo temporal
$yamlPath = "$env:TEMP\metrics-server-docker.yaml"
$metricsServerYaml | Out-File -FilePath $yamlPath -Encoding UTF8

Write-Host "Archivo guardado en: $yamlPath" -ForegroundColor Green

# PASO 5: Aplicar la configuración
Write-Host "Instalando Metrics Server..." -ForegroundColor Green
kubectl apply -f $yamlPath

# PASO 6: Esperar a que se inicie
Write-Host "Esperando a que Metrics Server se inicie (esto puede tomar 30-60 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# PASO 7: Monitorear hasta que esté listo
Write-Host "Monitoreando estado..." -ForegroundColor Cyan
kubectl get deployment metrics-server -n kube-system -w

# PASO 8: Verificar que funciona
Write-Host "`nVerificando que funciona..." -ForegroundColor Green
Start-Sleep -Seconds 10
kubectl top pods -n escalabilidad-lab --containers

Write-Host "`n✓ ¡Metrics Server instalado correctamente!" -ForegroundColor Green
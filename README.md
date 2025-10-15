# 🚀 Informe Técnico – Caso #1: Escalabilidad en Kubernetes

> 📅 **Fecha:** Octubre 2025  
> 👨‍💻 **Autor:** José David Escalante  
> 🧩 **Curso:** Kubernetes  
> 🖥️ **Entorno:** Docker Desktop + Kubernetes local  

---

## 📖 Resumen Ejecutivo

Este proyecto documenta el **análisis, diagnóstico e implementación de una solución de escalabilidad** en una aplicación web desplegada en **Kubernetes**.  
Durante los picos de tráfico, la aplicación mostraba **lentitud y alto consumo de CPU**, debido a que las réplicas estaban definidas de forma estática (3 pods fijos).

🔍 **Problema identificado:**
> Configuración estática de réplicas sin escalado automático basado en métricas.

💡 **Solución implementada:**
> Configuración de **Horizontal Pod Autoscaler (HPA)** con **requests/limits** definidos y umbral del **70 % de CPU**.

✅ **Resultado final:**
- Escalado automático funcional (de 3 a 10 réplicas)  
- CPU promedio por pod: de **200 m → 120 m**  
- Latencia reducida y mayor estabilidad  

---

## ⚙️ Tecnologías Utilizadas

| Componente | Descripción |
|-------------|-------------|
| 🐳 **Docker Desktop** | Entorno local con Kubernetes habilitado |
| ☸️ **Kubernetes v1.28+** | Orquestador principal |
| 🌐 **NGINX** | Aplicación web de prueba |
| 📊 **Metrics Server** | Fuente de métricas para el HPA |
| ⚖️ **HPA (Horizontal Pod Autoscaler)** | Mecanismo de escalado automático |

---

## 🧠 Descripción del Problema

**Síntomas observados:**
- Tiempos de respuesta lentos bajo carga.
- Uso de CPU > 200 m en cada pod.
- No existía escalado automático.
- Solo 3 réplicas estáticas definidas.

**Causa raíz:**
> Ausencia de `resources.requests` / `resources.limits` y de un `HorizontalPodAutoscaler`.

---

## 🔬 Diagnóstico y Análisis

| Métrica | Estado Inicial | Estado Esperado |
|----------|----------------|-----------------|
| Pods activos | 3 fijos | Dinámico según demanda |
| CPU promedio | 190–250 m | < 150 m |
| HPA configurado | ❌ No | ✅ Sí |
| Escalado automático | ❌ No | ✅ Sí |

📈 El clúster no reaccionaba al aumento de carga porque **Kubernetes no podía calcular el uso porcentual de CPU** sin recursos definidos.

---

## 🛠️ Implementación de la Solución

### 1️⃣ Definición de Recursos
```yaml
resources:
  requests:
    cpu: 50m
    memory: 30Mi
  limits:
    cpu: 100m
    memory: 64Mi
```

### 2️⃣ Configuración del HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-web-solucion
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 3️⃣ Despliegue en Kubernetes
```bash
kubectl apply -f deployment-solucion.yaml
kubectl apply -f service-solucion.yaml
kubectl apply -f hpa.yaml
```

---

## 📊 Resultados y Validación

| Indicador | Sin HPA | Con HPA | Mejora |
|------------|---------|---------|---------|
| Pods bajo carga | 3 (fijo) | 5–7 (dinámico) | 🔼 +133 % |
| CPU promedio/pod | 200 m | 110 m | 🔽 -56 % |
| Latencia | Alta | Estable | ✅ |
| Escalado automático | ❌ | ✅ | ✅ |
| Uso de recursos | Ineficiente | Óptimo | ✅ |

📸 **Evidencia visual:**  
Durante las pruebas de estrés, el HPA escaló automáticamente de **3 → 7 pods**, distribuyendo la carga de CPU y estabilizando el servicio.

---

## 🧩 Arquitectura Final

```text
[Usuarios] 
     ↓
┌──────────────────────────┐
│ Service (LoadBalancer)   │
│ app-web-service-solucion │
└──────────┬───────────────┘
           ↓
┌──────────────────────────┐
│ Deployment: web-solucion │
│ ├─ Pod1 │ ├─ Pod2 │ ... │ ├─ Pod10 │
└──────────┬───────────────┘
           ↓
     Horizontal Pod Autoscaler
     • Escala entre 3 y 10 pods
     • Umbral de CPU: 70 %
```

---

## 🧾 Lecciones Aprendidas

1. **Definir siempre `requests` y `limits`**: son esenciales para el cálculo del HPA.  
2. **El CPU es la métrica ideal** para aplicaciones web ligeras.  
3. **Umbral de 70 %** permite reaccionar antes de la saturación.  
4. **Ventanas de estabilización (5 min)** evitan oscilaciones constantes (flapping).  
5. **Monitoreo constante** con `kubectl top` y `kubectl get hpa` mejora la observabilidad.

---

## 🧰 Archivos Incluidos

- 📄 `deployment-problema.yaml`  
- 📄 `deployment-solucion.yaml`  
- ⚖️ `hpa.yaml`  
- 🌐 `service-problema.yaml` / `service-solucion.yaml`  
- 🧮 `metrics-server` instalación  
- 🧾 `script.ps1` (automatización)  
- ✅ `checklist-validacion.md`

---

## 🧭 Comandos Útiles

```bash
# Ver estado de HPA
kubectl get hpa -n escalabilidad-lab

# Monitorear métricas en tiempo real
kubectl top pods -n escalabilidad-lab --containers

# Ver eventos de escalado
kubectl get events -n escalabilidad-lab --sort-by='.lastTimestamp'
```

---

## 📚 Referencias

- [📘 Kubernetes – Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [⚙️ Resource Management for Pods](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [📊 Metrics Server GitHub](https://github.com/kubernetes-sigs/metrics-server)
- [🐳 Docker Desktop – Enable Kubernetes](https://docs.docker.com/desktop/kubernetes/)

---

## 🏁 Conclusión

> El proyecto demuestra la importancia de **diseñar despliegues dinámicos** en Kubernetes mediante **HPA y métricas de CPU**, logrando así **resiliencia, eficiencia y estabilidad** ante variaciones de carga.  

✨ *“Automatizar la respuesta ante la demanda es el primer paso hacia la verdadera elasticidad en la nube.”*

---

📄 **Autor:** José David Escalante  
📍 *Proyecto académico – Caso de Estudio de Escalabilidad Kubernetes (Octubre 2025)*

# 🎾  Padel Session Manager

App para gestionar torneos de pádel con seguimiento en tiempo real, rankings y brackets automáticos.

---

## 📋 ¿Qué hace la app?

Te permite organizar y administrar sesiones de pádel con:
- **3 tipos de torneos**: Tournament, Playoff 4 y Playoff 8
- **Control de juegos en tiempo real**: Inicia partidos, registra resultados
- **Rankings automáticos**: Sistema de puntuación dinámico
- **Modo espectador**: Código de 6 dígitos para que otros vean el torneo

---

## 🏅 Tipos de Sesión

### Tournament (T) / Optimized (O)
Torneo de 3 etapas progresivas

```
Etapa 1 (4 partidos) → Rankings
Etapa 2 (3 partidos) → Rankings  
Etapa 3 (2 partidos) → Ganador
```

- Todos los partidos se generan al inicio
- Botón "Avanzar a Etapa X" aparece al completar cada etapa
- Los emparejamientos se basan en el ranking actual

### Playoff 4 (P4)
Fase de grupos → Top 4 → Final

```
Grupos (8 partidos) → Top 4 clasifican → Final
```

- Extensa fase de grupos
- Los mejores 4 pasan a la final
- Un solo partido determina el campeón

### Playoff 8 (P8)
Fase de grupos → Top 8 → Semifinales → Finales

```
Grupos (7 partidos) → Top 8 clasifican
Semifinales (2 partidos) 
Finales: Oro y Bronce (auto-generadas)
```

- Los mejores 8 clasifican
- Semifinales: #1 vs #8, #2 vs #7, #3 vs #6, #4 vs #5
- Las finales de Oro y Bronce se generan automáticamente
 

---

## 📱 Cómo usar la app

### 1. Crear una sesión
- Selecciona tipo de torneo (Tournament, P4 o P8)
- Configura: canchas, duración, jugadores, puntos por juego
- Recibe un **código de 6 dígitos** para compartir

### 2. Iniciar partidos
- **Tab "Next"**: Lista de partidos pendientes
- Presiona **"Start Game"** en partidos con cancha asignada
- O usa **"Skip the Line"** para priorizar cualquier partido

### 3. Registrar resultados
- **Tab "Live"**: Partidos en curso
- Presiona **"Record Result"**
- Ingresa puntajes (Best of 1 o Best of 3)
- Los rankings se actualizan automáticamente

### 4. Avanzar de etapa

**Para Tournament:**
- Completa todos los partidos de la etapa actual
- Presiona **"Advance to Stage X"**
- Se generan nuevos partidos basados en el ranking

**Para Playoffs (P4/P8):**
- Completa todos los partidos de grupos
- Presiona **"Advance to Playoffs"**
- Se genera el bracket automáticamente

**Para P8 (Finales):**
- Al completar semifinales, las finales se **auto-generan**

### 5. Finalizar sesión
- Click en el timer (esquina superior derecha)
- **"Finalize Session"**
- Se muestra el podio con ganadores

---
 

### Componentes principales

**SessionControlPanel.dart**
- Control completo de la sesión
- 4 tabs: Live, Next, Completed, Rankings
- Actualización automática cada 15 segundos
- Timer de sesión

**ScoreEntryDialog.dart**
- Registro de puntajes
- Soporte Best of 1 y Best of 3
- Validación de ganadores
- Modo edición para partidos completados

**SessionService.dart**
- Endpoints REST con autenticación Bearer token
- Manejo de sesiones, juegos y jugadores

---

## 🔗 API (Backend Laravel)

### Endpoints principales

```dart
GET    /sessions/{id}                  // Obtener sesión
GET    /sessions/{id}/games/status     // Obtener juegos por estado
POST   /games/{id}/start               // Iniciar juego
POST   /games/{id}/submit-score        // Enviar resultado
POST   /sessions/{id}/advance-stage    // Avanzar etapa
POST   /sessions/{id}/finalize         // Finalizar sesión
```
 
---

## ⚙️ Características técnicas

### State Management
- `StatefulWidget` con `TabController`
- Timers: auto-refresh (15s) y sesión (1s)
- Estado local: `_sessionData`, `_liveGames`, `_nextGames`, `_players`

### Funcionalidades destacadas
- ✅ Auto-refresh cada 15 segundos
- ✅ Detección automática de espectador
- ✅ Asignación inteligente de canchas
- ✅ Cola visual de partidos
- ✅ Edición retroactiva de puntajes
- ✅ Cálculo dinámico de rankings con ELO
- ✅ Soporte Best of 3 con sets individuales
- ✅ Modo espectador (solo lectura)

 

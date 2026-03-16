<template>
  <div class="container">
    <header>
      <h1>🦀 OpenClaw Monitor</h1>
      <p class="subtitle">实时系统监控仪表盘</p>
      <div class="status-bar">
        <span :class="['status-indicator', gatewayOnline ? 'online' : 'offline']"></span>
        <span>{{ gatewayOnline ? 'Gateway 在线' : 'Gateway 离线' }}</span>
        <span class="last-update">最后更新：{{ lastUpdateTime }}</span>
      </div>
    </header>

    <!-- 告警横幅 -->
    <div v-if="alerts.length > 0" class="alerts-banner">
      <div v-for="(alert, index) in alerts" :key="index" :class="['alert', alert.level]">
        <span class="alert-icon">{{ alert.level === 'critical' ? '🚨' : '⚠️' }}</span>
        <span class="alert-message">{{ alert.message }}</span>
        <button @click="dismissAlert(index)" class="alert-dismiss">×</button>
      </div>
    </div>

    <main class="dashboard">
      <!-- Gateway 状态卡片 -->
      <section class="card">
        <h2>🖥️ Gateway 状态</h2>
        <div class="stats-grid">
          <div class="stat">
            <label>运行时间</label>
            <div class="value">{{ gatewayInfo.uptime || '-' }}</div>
          </div>
          <div class="stat">
            <label>模型</label>
            <div class="value">{{ gatewayInfo.model || '-' }}</div>
          </div>
          <div class="stat">
            <label>Shell</label>
            <div class="value">{{ gatewayInfo.shell || '-' }}</div>
          </div>
        </div>
      </section>

      <!-- Session 监控卡片 -->
      <section class="card">
        <h2>💬 Session 监控</h2>
        <div class="stats-grid">
          <div class="stat">
            <label>活跃 Session</label>
            <div class="value">{{ sessionStats.active }}</div>
          </div>
          <div class="stat">
            <label>总消息数</label>
            <div class="value">{{ sessionStats.totalMessages }}</div>
          </div>
          <div class="stat">
            <label>Sub-agents</label>
            <div class="value">{{ sessionStats.subAgents }}</div>
          </div>
        </div>
        <div class="extra-stats">
          <div class="mini-stat">
            <label>今日消息</label>
            <div class="value">{{ sessionStats.todayMessages }}</div>
          </div>
          <div class="mini-stat">
            <label>错误数</label>
            <div class="value" :class="{ warning: sessionStats.errorCount > 10 }">{{ sessionStats.errorCount }}</div>
          </div>
        </div>
      </section>

      <!-- 系统资源卡片 -->
      <section class="card">
        <h2>📊 系统资源</h2>
        <div class="stats-grid">
          <div class="stat" :class="{ warning: systemInfo.cpu > 70, critical: systemInfo.cpu > 90 }">
            <label>CPU 使用率</label>
            <div class="value">{{ systemInfo.cpu }}%</div>
            <div class="progress-bar">
              <div class="progress" :style="{ width: systemInfo.cpu + '%' }" :class="getProgressClass(systemInfo.cpu)"></div>
            </div>
          </div>
          <div class="stat" :class="{ warning: systemInfo.memory > 70, critical: systemInfo.memory > 90 }">
            <label>内存使用率</label>
            <div class="value">{{ systemInfo.memory }}%</div>
            <div class="progress-bar">
              <div class="progress" :style="{ width: systemInfo.memory + '%' }" :class="getProgressClass(systemInfo.memory)"></div>
            </div>
          </div>
          <div class="stat" :class="{ warning: systemInfo.disk > 70, critical: systemInfo.disk > 85 }">
            <label>磁盘使用率</label>
            <div class="value">{{ systemInfo.disk }}%</div>
            <div class="progress-bar">
              <div class="progress" :style="{ width: systemInfo.disk + '%' }" :class="getProgressClass(systemInfo.disk)"></div>
            </div>
          </div>
        </div>
      </section>

      <!-- Cron 任务卡片 -->
      <section class="card">
        <h2>⏰ Cron 任务</h2>
        <div class="stats-grid">
          <div class="stat">
            <label>总任务数</label>
            <div class="value">{{ cronStats.total }}</div>
          </div>
          <div class="stat">
            <label>已启用</label>
            <div class="value">{{ cronStats.enabled }}</div>
          </div>
          <div class="stat">
            <label>待执行</label>
            <div class="value">{{ cronStats.pending }}</div>
          </div>
        </div>
        <div class="extra-stats">
          <div class="mini-stat">
            <label>今日执行</label>
            <div class="value">{{ cronStats.todayRuns }}</div>
          </div>
          <div class="mini-stat">
            <label>失败数</label>
            <div class="value" :class="{ warning: cronStats.failures > 0 }">{{ cronStats.failures }}</div>
          </div>
        </div>
      </section>

      <!-- CPU 使用率图表 -->
      <section class="card chart-card">
        <h2>📈 CPU 使用率趋势</h2>
        <div class="chart-container">
          <canvas ref="cpuChart"></canvas>
        </div>
      </section>

      <!-- 内存使用率图表 -->
      <section class="card chart-card">
        <h2>💾 内存使用率趋势</h2>
        <div class="chart-container">
          <canvas ref="memoryChart"></canvas>
        </div>
      </section>

      <!-- 资源分布饼图 -->
      <section class="card chart-card">
        <h2>🥧 资源分布</h2>
        <div class="chart-container pie">
          <canvas ref="resourcePieChart"></canvas>
        </div>
      </section>

      <!-- 消息通道状态 -->
      <section class="card">
        <h2>📡 消息通道</h2>
        <div class="channel-list">
          <div v-for="channel in channels" :key="channel.name" class="channel-item">
            <span class="channel-icon">{{ channel.icon }}</span>
            <span class="channel-name">{{ channel.name }}</span>
            <span :class="['channel-status', channel.online ? 'online' : 'offline']"></span>
            <span class="channel-messages">{{ channel.messages }} 条</span>
          </div>
        </div>
      </section>

      <!-- 日志流 -->
      <section class="card logs-card">
        <h2>📜 实时日志</h2>
        <div class="logs-container">
          <div v-for="(log, index) in logs" :key="index" :class="['log-entry', log.level]">
            <span class="log-time">{{ log.time }}</span>
            <span class="log-message">{{ log.message }}</span>
          </div>
          <div v-if="logs.length === 0" class="no-logs">暂无日志</div>
        </div>
      </section>
    </main>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

export default {
  name: 'App',
  setup() {
    const gatewayOnline = ref(true)
    const lastUpdateTime = ref(new Date().toLocaleTimeString())
    const alerts = ref([])
    
    const cpuChart = ref(null)
    const memoryChart = ref(null)
    const resourcePieChart = ref(null)
    
    const gatewayInfo = ref({
      uptime: '-',
      model: '-',
      shell: '-'
    })
    
    const sessionStats = ref({
      active: 0,
      totalMessages: 0,
      subAgents: 0,
      todayMessages: 0,
      errorCount: 0
    })
    
    const systemInfo = ref({
      cpu: 0,
      memory: 0,
      disk: 0
    })
    
    const cronStats = ref({
      total: 0,
      enabled: 0,
      pending: 0,
      todayRuns: 0,
      failures: 0
    })
    
    const channels = ref([
      { name: 'OpenIM', icon: '💬', online: true, messages: 156 },
      { name: 'Telegram', icon: '✈️', online: true, messages: 89 },
      { name: 'Discord', icon: '🎮', online: false, messages: 0 },
      { name: 'WhatsApp', icon: '📱', online: true, messages: 234 }
    ])
    
    const logs = ref([])
    
    // 历史数据用于图表
    const cpuHistory = ref([])
    const memoryHistory = ref([])
    const timeLabels = ref([])
    
    let refreshInterval = null
    let cpuChartInstance = null
    let memoryChartInstance = null
    let pieChartInstance = null
    
    const getProgressClass = (value) => {
      if (value > 90) return 'critical'
      if (value > 70) return 'warning'
      return 'normal'
    }
    
    const checkAlerts = (cpu, memory, disk) => {
      const newAlerts = []
      
      if (cpu > 90) {
        newAlerts.push({ level: 'critical', message: `CPU 使用率过高：${cpu}%` })
      } else if (cpu > 80) {
        newAlerts.push({ level: 'warning', message: `CPU 使用率较高：${cpu}%` })
      }
      
      if (memory > 90) {
        newAlerts.push({ level: 'critical', message: `内存使用率过高：${memory}%` })
      } else if (memory > 80) {
        newAlerts.push({ level: 'warning', message: `内存使用率较高：${memory}%` })
      }
      
      if (disk > 85) {
        newAlerts.push({ level: 'critical', message: `磁盘空间不足：${disk}%` })
      } else if (disk > 75) {
        newAlerts.push({ level: 'warning', message: `磁盘空间较少：${disk}%` })
      }
      
      alerts.value = newAlerts
    }
    
    const dismissAlert = (index) => {
      alerts.value.splice(index, 1)
    }
    
    const initCharts = () => {
      // CPU 折线图
      const cpuCtx = cpuChart.value?.getContext('2d')
      if (cpuCtx) {
        cpuChartInstance = new Chart(cpuCtx, {
          type: 'line',
          data: {
            labels: timeLabels.value,
            datasets: [{
              label: 'CPU %',
              data: cpuHistory.value,
              borderColor: '#60a5fa',
              backgroundColor: 'rgba(96, 165, 250, 0.1)',
              fill: true,
              tension: 0.4,
              pointRadius: 2
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: false,
            scales: {
              y: {
                beginAtZero: true,
                max: 100,
                grid: { color: 'rgba(255, 255, 255, 0.1)' },
                ticks: { color: 'rgba(255, 255, 255, 0.7)' }
              },
              x: {
                grid: { color: 'rgba(255, 255, 255, 0.05)' },
                ticks: { color: 'rgba(255, 255, 255, 0.5)', maxTicksLimit: 10 }
              }
            },
            plugins: {
              legend: { display: false }
            }
          }
        })
      }
      
      // 内存折线图
      const memoryCtx = memoryChart.value?.getContext('2d')
      if (memoryCtx) {
        memoryChartInstance = new Chart(memoryCtx, {
          type: 'line',
          data: {
            labels: timeLabels.value,
            datasets: [{
              label: 'Memory %',
              data: memoryHistory.value,
              borderColor: '#34d399',
              backgroundColor: 'rgba(52, 211, 153, 0.1)',
              fill: true,
              tension: 0.4,
              pointRadius: 2
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: false,
            scales: {
              y: {
                beginAtZero: true,
                max: 100,
                grid: { color: 'rgba(255, 255, 255, 0.1)' },
                ticks: { color: 'rgba(255, 255, 255, 0.7)' }
              },
              x: {
                grid: { color: 'rgba(255, 255, 255, 0.05)' },
                ticks: { color: 'rgba(255, 255, 255, 0.5)', maxTicksLimit: 10 }
              }
            },
            plugins: {
              legend: { display: false }
            }
          }
        })
      }
      
      // 资源分布饼图
      const pieCtx = resourcePieChart.value?.getContext('2d')
      if (pieCtx) {
        pieChartInstance = new Chart(pieCtx, {
          type: 'doughnut',
          data: {
            labels: ['CPU', '内存', '磁盘'],
            datasets: [{
              data: [systemInfo.value.cpu, systemInfo.value.memory, systemInfo.value.disk],
              backgroundColor: [
                'rgba(96, 165, 250, 0.8)',
                'rgba(52, 211, 153, 0.8)',
                'rgba(251, 191, 36, 0.8)'
              ],
              borderWidth: 0
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '60%',
            plugins: {
              legend: {
                position: 'bottom',
                labels: { color: 'rgba(255, 255, 255, 0.7)', padding: 15 }
              }
            }
          }
        })
      }
    }
    
    const updateCharts = () => {
      // 更新历史数据
      const now = new Date()
      const timeLabel = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
      
      timeLabels.value.push(timeLabel)
      cpuHistory.value.push(systemInfo.value.cpu)
      memoryHistory.value.push(systemInfo.value.memory)
      
      // 保持最近 30 个数据点
      if (timeLabels.value.length > 30) {
        timeLabels.value.shift()
        cpuHistory.value.shift()
        memoryHistory.value.shift()
      }
      
      // 更新折线图
      if (cpuChartInstance) {
        cpuChartInstance.data.labels = timeLabels.value
        cpuChartInstance.data.datasets[0].data = cpuHistory.value
        cpuChartInstance.update('none')
      }
      
      if (memoryChartInstance) {
        memoryChartInstance.data.labels = timeLabels.value
        memoryChartInstance.data.datasets[0].data = memoryHistory.value
        memoryChartInstance.update('none')
      }
      
      // 更新饼图
      if (pieChartInstance) {
        pieChartInstance.data.datasets[0].data = [systemInfo.value.cpu, systemInfo.value.memory, systemInfo.value.disk]
        pieChartInstance.update('none')
      }
    }
    
    const fetchData = async () => {
      try {
        // 模拟数据 - 实际项目中会调用 Tauri API
        gatewayInfo.value = {
          uptime: '2h 15m',
          model: 'qwen3.5-plus',
          shell: 'bash'
        }
        
        sessionStats.value = {
          active: Math.floor(Math.random() * 5) + 1,
          totalMessages: Math.floor(Math.random() * 100) + 50,
          subAgents: Math.floor(Math.random() * 3),
          todayMessages: Math.floor(Math.random() * 500) + 200,
          errorCount: Math.floor(Math.random() * 5)
        }
        
        systemInfo.value = {
          cpu: Math.floor(Math.random() * 30) + 10,
          memory: Math.floor(Math.random() * 40) + 30,
          disk: Math.floor(Math.random() * 20) + 40
        }
        
        cronStats.value = {
          total: Math.floor(Math.random() * 10) + 2,
          enabled: Math.floor(Math.random() * 8) + 2,
          pending: Math.floor(Math.random() * 3),
          todayRuns: Math.floor(Math.random() * 50) + 10,
          failures: Math.floor(Math.random() * 2)
        }
        
        // 更新通道消息数
        channels.value.forEach(ch => {
          if (ch.online) {
            ch.messages += Math.floor(Math.random() * 5)
          }
        })
        
        // 检查告警
        checkAlerts(systemInfo.value.cpu, systemInfo.value.memory, systemInfo.value.disk)
        
        // 更新图表
        updateCharts()
        
        // 添加日志
        if (Math.random() > 0.7) {
          const levels = ['info', 'warn', 'error']
          const messages = [
            '系统状态正常',
            'Session 活动检测',
            'Cron 任务执行完成',
            'Gateway 心跳正常',
            '消息发送成功',
            '内存回收完成'
          ]
          logs.value.unshift({
            time: new Date().toLocaleTimeString(),
            level: levels[Math.floor(Math.random() * levels.length)],
            message: messages[Math.floor(Math.random() * messages.length)]
          })
          logs.value = logs.value.slice(0, 20)
        }
        
        lastUpdateTime.value = new Date().toLocaleTimeString()
      } catch (error) {
        console.error('获取数据失败:', error)
        gatewayOnline.value = false
      }
    }
    
    onMounted(async () => {
      await nextTick()
      initCharts()
      fetchData()
      refreshInterval = setInterval(fetchData, 3000) // 每 3 秒刷新
    })
    
    onUnmounted(() => {
      if (refreshInterval) {
        clearInterval(refreshInterval)
      }
      if (cpuChartInstance) {
        cpuChartInstance.destroy()
      }
      if (memoryChartInstance) {
        memoryChartInstance.destroy()
      }
      if (pieChartInstance) {
        pieChartInstance.destroy()
      }
    })
    
    return {
      gatewayOnline,
      lastUpdateTime,
      alerts,
      dismissAlert,
      gatewayInfo,
      sessionStats,
      systemInfo,
      cronStats,
      channels,
      logs,
      cpuChart,
      memoryChart,
      resourcePieChart,
      getProgressClass
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  min-height: 100vh;
  color: #fff;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
}

header {
  text-align: center;
  margin-bottom: 30px;
  padding: 20px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 15px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

h1 {
  font-size: 2.5em;
  margin-bottom: 10px;
}

.subtitle {
  color: rgba(255, 255, 255, 0.7);
  font-size: 1.1em;
  margin-bottom: 15px;
}

.status-bar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  font-size: 0.9em;
}

.status-indicator {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

.status-indicator.online {
  background: #4ade80;
}

.status-indicator.offline {
  background: #f87171;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.last-update {
  color: rgba(255, 255, 255, 0.5);
  margin-left: 20px;
}

/* 告警横幅 */
.alerts-banner {
  margin-bottom: 20px;
}

.alert {
  padding: 15px 20px;
  margin-bottom: 10px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  gap: 10px;
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from {
    transform: translateY(-20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.alert.critical {
  background: rgba(239, 68, 68, 0.2);
  border: 1px solid #ef4444;
  animation: pulse-alert 1s infinite;
}

.alert.warning {
  background: rgba(251, 191, 36, 0.2);
  border: 1px solid #fbbf24;
}

@keyframes pulse-alert {
  0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
  50% { box-shadow: 0 0 0 10px rgba(239, 68, 68, 0); }
}

.alert-icon {
  font-size: 1.5em;
}

.alert-message {
  flex: 1;
  font-weight: 500;
}

.alert-dismiss {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  font-size: 1.5em;
  cursor: pointer;
  padding: 0 5px;
}

.alert-dismiss:hover {
  color: #fff;
}

.dashboard {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(10px);
  border-radius: 15px;
  padding: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.card h2 {
  font-size: 1.3em;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
}

.stat {
  text-align: center;
  padding: 15px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 10px;
  transition: all 0.3s ease;
}

.stat.warning {
  background: rgba(251, 191, 36, 0.1);
  border: 1px solid rgba(251, 191, 36, 0.3);
}

.stat.critical {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  animation: pulse-critical 1s infinite;
}

@keyframes pulse-critical {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.02); }
}

.stat label {
  display: block;
  font-size: 0.85em;
  color: rgba(255, 255, 255, 0.6);
  margin-bottom: 8px;
}

.stat .value {
  font-size: 1.5em;
  font-weight: bold;
  color: #60a5fa;
}

.stat.warning .value {
  color: #fbbf24;
}

.stat.critical .value {
  color: #ef4444;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
  margin-top: 10px;
  overflow: hidden;
}

.progress {
  height: 100%;
  border-radius: 3px;
  transition: width 0.5s ease;
}

.progress.normal {
  background: linear-gradient(90deg, #60a5fa, #34d399);
}

.progress.warning {
  background: linear-gradient(90deg, #fbbf24, #f59e0b);
}

.progress.critical {
  background: linear-gradient(90deg, #ef4444, #dc2626);
}

.extra-stats {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.mini-stat {
  text-align: center;
  padding: 10px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 8px;
}

.mini-stat label {
  font-size: 0.75em;
  color: rgba(255, 255, 255, 0.5);
  margin-bottom: 5px;
}

.mini-stat .value {
  font-size: 1.2em;
  color: #60a5fa;
}

.mini-stat .value.warning {
  color: #fbbf24;
}

/* 图表卡片 */
.chart-card {
  grid-column: span 1;
}

.chart-container {
  height: 250px;
  position: relative;
}

.chart-container.pie {
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 通道列表 */
.channel-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.channel-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 15px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 8px;
  transition: background 0.2s ease;
}

.channel-item:hover {
  background: rgba(255, 255, 255, 0.08);
}

.channel-icon {
  font-size: 1.5em;
}

.channel-name {
  flex: 1;
  font-weight: 500;
}

.channel-status {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.channel-status.online {
  background: #4ade80;
}

.channel-status.offline {
  background: #6b7280;
}

.channel-messages {
  font-size: 0.85em;
  color: rgba(255, 255, 255, 0.5);
}

/* 日志卡片 */
.logs-card {
  grid-column: 1 / -1;
}

.logs-container {
  max-height: 300px;
  overflow-y: auto;
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
}

.log-entry {
  padding: 8px 12px;
  margin-bottom: 5px;
  border-radius: 5px;
  display: flex;
  gap: 15px;
}

.log-entry.info {
  background: rgba(59, 130, 246, 0.2);
  border-left: 3px solid #3b82f6;
}

.log-entry.warn {
  background: rgba(251, 191, 36, 0.2);
  border-left: 3px solid #fbbf24;
}

.log-entry.error {
  background: rgba(239, 68, 68, 0.2);
  border-left: 3px solid #ef4444;
}

.log-time {
  color: rgba(255, 255, 255, 0.5);
  min-width: 80px;
}

.log-message {
  flex: 1;
}

.no-logs {
  text-align: center;
  color: rgba(255, 255, 255, 0.5);
  padding: 20px;
}

/* 滚动条 */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.3);
}

/* 响应式 */
@media (max-width: 768px) {
  .dashboard {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  h1 {
    font-size: 1.8em;
  }
}
</style>

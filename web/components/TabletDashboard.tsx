import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import {
  Activity,
  AlertTriangle,
  BarChart3,
  Flag,
  History,
  Map,
  Radio,
  Settings,
  Trophy,
  Wifi,
  X,
  Zap
} from 'lucide-react';
import { fetchNui } from '../hooks/useNui';
import { t } from '../hooks/useLocale';
import type { LobbySummary, NetworkData, PlayerStats, RouteSummary, TabletSettings } from '../App';
import LobbyPanel from './LobbyPanel';
import LeaderboardPanel from './LeaderboardPanel';
import MyStatsPanel from './MyStatsPanel';
import RaceHistoryPanel from './RaceHistoryPanel';
import RoutesPanel from './RoutesPanel';
import NetworkPanel from './NetworkPanel';
import SettingsPanel from './SettingsPanel';

interface TabletDashboardProps {
  playerRep: number;
  lobbyData: any;
  availableLobbies: LobbySummary[];
  routes: RouteSummary[];
  leaderboardData: any[];
  playerStats: PlayerStats;
  networkData: NetworkData;
  settings: TabletSettings;
  serverId: number | null;
  onClose: () => void;
}

type Tab = 'lobby' | 'routes' | 'leaderboard' | 'history' | 'stats' | 'network' | 'settings';

const tabs = [
  { id: 'lobby' as Tab, labelKey: 'lobby', label: 'Lobby', icon: Flag },
  { id: 'routes' as Tab, labelKey: 'routes', label: 'Routes', icon: Map },
  { id: 'leaderboard' as Tab, labelKey: 'ranks', label: 'Ranks', icon: Trophy },
  { id: 'history' as Tab, labelKey: 'history', label: 'History', icon: History },
  { id: 'stats' as Tab, labelKey: 'my_stats', label: 'My Stats', icon: BarChart3 }
];

const speedLineStyles = Array.from({ length: 8 }, (_, i) => ({
  top: `${5 + i * 12}%`,
  width: `${36 + (i % 4) * 10}%`,
  animationDelay: `${i * 0.5}s`,
  animationDuration: `${3 + (i % 3) * 0.5}s`
}));

export default function TabletDashboard({
  playerRep,
  lobbyData,
  availableLobbies,
  routes,
  leaderboardData,
  playerStats,
  networkData,
  settings,
  serverId,
  onClose
}: TabletDashboardProps) {
  const [activeTab, setActiveTab] = useState<Tab>('lobby');
  const policeAlert = settings.policeAlerts !== false && (networkData?.nearbyPoliceCount || 0) > 0;
  const themeClass = settings.theme === 'light' ? 'tablet-theme-light' : 'tablet-theme-dark';

  useEffect(() => {
    const refreshPanel = () => {
      if (activeTab === 'leaderboard') fetchNui('getLeaderboard', {}, { success: true });
      if (activeTab === 'lobby') fetchNui('getLobbies', {}, { success: true });
      if (activeTab === 'routes') fetchNui('getRoutes', {}, { success: true });
      if (activeTab === 'stats' || activeTab === 'history') fetchNui('getStats', {}, { success: true });
      if (activeTab === 'network') {
        fetchNui('getNetwork', {}, { success: true });
        fetchNui('getRaceRadio', {}, { success: true });
      }
      if (activeTab === 'settings') fetchNui('getSettings', {}, { success: true });
    };

    refreshPanel();
    const interval = window.setInterval(refreshPanel, activeTab === 'network' ? 5000 : 15000);
    return () => window.clearInterval(interval);
  }, [activeTab]);

  const activityFeed = [
    { type: 'race_start', label: `${networkData.lobbyCount || 0} lobby open` },
    { type: 'race_end', label: `${networkData.activeRaceCount || 0} active race` },
    { type: 'record', label: `${playerStats.personalRecords?.length || 0} personal records` },
    { type: 'new_rank', label: `${networkData.onlineCount || 0} racers online` },
    ...(policeAlert ? [{ type: 'police', label: `${networkData.nearbyPoliceCount} police nearby` }] : [])
  ];

  return (
    <div className="w-screen h-screen flex items-center justify-center pointer-events-auto p-3 md:p-5">
      <motion.div
        initial={{ scale: 0.96, opacity: 0, y: 24 }}
        animate={{ scale: 1, opacity: 1, y: 0 }}
        exit={{ scale: 0.96, opacity: 0, y: 24 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        className={`tablet-shell ${themeClass} relative w-full max-w-6xl h-[88vh]`}
      >
        <div className="tablet-camera" />
        <div className="tablet-speaker" />
        <div className="tablet-home-indicator" />
        <div className="tablet-side-button tablet-side-button-left" />
        <div className="tablet-side-button tablet-side-button-right" />

        <div className="tablet-screen tablet-frame relative h-full overflow-hidden flex">
          <div className="tablet-grid-bg" />
          <div className="tablet-screen-scanlines" />

          <div className="tablet-sidebar w-20 border-r border-red-900/30 flex flex-col items-center py-6 relative z-20">
            <div className="mb-8">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-red-600 to-red-950 flex items-center justify-center border border-red-500/50 shadow-lg shadow-red-500/20">
                <Zap size={24} className="text-white" strokeWidth={2.5} />
              </div>
            </div>

            <nav className="flex-1 flex flex-col gap-2 w-full px-2">
              {tabs.map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`nav-item w-full py-3 rounded-lg flex flex-col items-center gap-1 transition-all relative group ${
                      isActive
                        ? 'bg-red-950/60 border border-red-500/40'
                        : 'hover:bg-zinc-900/60 border border-transparent'
                    }`}
                  >
                    <Icon
                      size={22}
                      className={`transition-all ${isActive ? 'text-red-400' : 'text-zinc-500 group-hover:text-zinc-300'}`}
                    />
                    <span className={`text-[10px] uppercase font-semibold ${
                      isActive ? 'text-red-400' : 'text-zinc-600 group-hover:text-zinc-400'
                    }`}>
                      {t(tab.labelKey, tab.label)}
                    </span>
                    {isActive && (
                      <motion.div
                        layoutId="activeTab"
                        className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-red-500 rounded-r"
                      />
                    )}
                  </button>
                );
              })}
            </nav>

            <div className="mt-auto w-full px-2 space-y-2">
              <button
                onClick={() => setActiveTab('network')}
                aria-label="Open network"
                className={`w-full py-2 rounded-lg flex items-center justify-center transition-all ${
                  activeTab === 'network'
                    ? 'text-red-400 bg-red-950/60 border border-red-500/40'
                    : 'text-zinc-600 hover:text-zinc-400 hover:bg-zinc-900/40'
                }`}
              >
                <Radio size={18} />
              </button>
              <button
                onClick={() => setActiveTab('settings')}
                aria-label="Open settings"
                className={`w-full py-2 rounded-lg flex items-center justify-center transition-all ${
                  activeTab === 'settings'
                    ? 'text-red-400 bg-red-950/60 border border-red-500/40'
                    : 'text-zinc-600 hover:text-zinc-400 hover:bg-zinc-900/40'
                }`}
              >
                <Settings size={18} />
              </button>
            </div>
          </div>

          <div className="flex-1 flex flex-col bg-gradient-to-br from-zinc-950 via-black to-zinc-950 relative overflow-hidden z-10">
            <div className="speed-lines-bg">
              {speedLineStyles.map((style, i) => (
                <div
                  key={i}
                  className={`speed-line ${i % 2 === 0 ? 'reverse' : ''}`}
                  style={style}
                />
              ))}
            </div>

            <AnimatePresence>
              {policeAlert && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="relative z-20 bg-gradient-to-r from-red-950 via-red-900/80 to-red-950 border-b border-red-700/50 overflow-hidden"
                >
                  <div className="px-6 py-2 flex items-center justify-center gap-3">
                    <AlertTriangle size={14} className="text-red-400 animate-pulse" />
                    <span className="text-red-200 text-sm font-semibold">
                      {t('police_activity', 'POLICE ACTIVITY DETECTED NEAR ACTIVE ROUTE')}
                    </span>
                    <AlertTriangle size={14} className="text-red-400 animate-pulse" />
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <div className="relative z-10 px-6 py-3 border-b border-red-900/20 flex items-center justify-between bg-black/70">
              <div className="flex items-center gap-4 min-w-0">
                <h1 className="glitch-text text-xl font-bold text-white whitespace-nowrap" data-text="UNDERGROUND RACING">
                  <span className="text-red-500">UNDERGROUND</span> RACING
                </h1>
                <div className="h-6 w-px bg-zinc-800" />
                <div className="w-64 overflow-hidden hidden md:block">
                  <motion.div
                    animate={{ x: ['0%', '-50%'] }}
                    transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
                    className="flex gap-8 whitespace-nowrap"
                  >
                    {[...activityFeed, ...activityFeed].map((item, i) => (
                      <span key={i} className="text-zinc-500 text-xs flex items-center gap-1">
                        {item.type === 'police' ? (
                          <AlertTriangle size={10} className="text-red-400" />
                        ) : item.type === 'race_end' ? (
                          <Trophy size={10} className="text-yellow-500" />
                        ) : item.type === 'record' ? (
                          <History size={10} className="text-red-400" />
                        ) : (
                          <Flag size={10} className="text-green-400" />
                        )}
                        <span className="text-zinc-400">{item.label}</span>
                      </span>
                    ))}
                  </motion.div>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="hidden lg:flex items-center gap-2 bg-black/40 border border-zinc-800 rounded px-3 py-1.5">
                  <Wifi size={12} className="text-green-400 animate-pulse" />
                  <span className="text-zinc-400 text-xs font-semibold">CONNECTED</span>
                </div>
                <div className="hidden lg:flex items-center gap-2 bg-black/40 border border-zinc-800 rounded px-3 py-1.5">
                  <Activity size={12} className="text-red-400" />
                  <span className="text-zinc-400 text-xs font-semibold">{networkData.onlineCount || 0} ONLINE</span>
                </div>
                <div className="flex items-center gap-2 bg-black/40 border border-red-900/30 rounded px-3 py-1.5 group hover:border-red-600/50 transition-all">
                  <Trophy size={14} className="text-yellow-500" />
                  <span className="text-red-400 font-bold text-sm">{playerRep}</span>
                  <span className="text-zinc-600 text-xs">REP</span>
                  <div className="w-1 h-1 rounded-full bg-green-400 animate-pulse" />
                </div>
                <button
                  onClick={onClose}
                  aria-label="Close racing tablet"
                  className="w-8 h-8 rounded bg-zinc-900/60 border border-zinc-800 hover:border-red-500/50 hover:bg-red-950/40 flex items-center justify-center text-zinc-500 hover:text-red-400 transition-all"
                >
                  <X size={18} />
                </button>
              </div>
            </div>

            <div className="flex-1 overflow-hidden relative z-10">
              <AnimatePresence mode="wait">
                {activeTab === 'lobby' && (
                  <PanelShell keyName="lobby">
                    <LobbyPanel
                      lobbyData={lobbyData}
                      availableLobbies={availableLobbies}
                      routes={routes}
                      playerRep={playerRep}
                      serverId={serverId}
                      activeRaceCount={networkData.activeRaceCount || 0}
                      nearbyPoliceCount={networkData.nearbyPoliceCount || 0}
                      onNavigate={setActiveTab}
                    />
                  </PanelShell>
                )}
                {activeTab === 'routes' && (
                  <PanelShell keyName="routes">
                    <RoutesPanel playerRep={playerRep} routes={routes} />
                  </PanelShell>
                )}
                {activeTab === 'leaderboard' && (
                  <PanelShell keyName="leaderboard">
                    <LeaderboardPanel data={leaderboardData} playerRep={playerRep} playerRank={playerStats.rank} />
                  </PanelShell>
                )}
                {activeTab === 'history' && (
                  <PanelShell keyName="history">
                    <RaceHistoryPanel stats={playerStats} routes={routes} />
                  </PanelShell>
                )}
                {activeTab === 'stats' && (
                  <PanelShell keyName="stats">
                    <MyStatsPanel playerRep={playerRep} stats={playerStats} />
                  </PanelShell>
                )}
                {activeTab === 'network' && (
                  <PanelShell keyName="network">
                    <NetworkPanel data={networkData} serverId={serverId} />
                  </PanelShell>
                )}
                {activeTab === 'settings' && (
                  <PanelShell keyName="settings">
                    <SettingsPanel settings={settings} />
                  </PanelShell>
                )}
              </AnimatePresence>
            </div>
          </div>

          <div className="tablet-reflection" />
        </div>
      </motion.div>
    </div>
  );
}

function PanelShell({ children, keyName }: { children: ReactNode; keyName: string }) {
  return (
    <motion.div
      key={keyName}
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      transition={{ duration: 0.2 }}
      className="h-full overflow-y-auto p-6"
    >
      {children}
    </motion.div>
  );
}

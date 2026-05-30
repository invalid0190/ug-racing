import { motion } from 'framer-motion';
import { AlertTriangle, Building2, Car, Clock, Flag, Gauge, Lock, Map, Mountain, Zap } from 'lucide-react';
import { fetchNui } from '../hooks/useNui';
import type { RouteSummary } from '../App';

interface RoutesPanelProps {
  playerRep: number;
  routes: RouteSummary[];
}

const difficultyColors = {
  Easy: 'text-green-400 bg-green-950/40 border-green-900/40',
  Medium: 'text-yellow-400 bg-yellow-950/40 border-yellow-900/40',
  Hard: 'text-red-400 bg-red-950/40 border-red-900/40'
};

const typeIcons = {
  urban: Building2,
  industrial: Zap,
  hills: Mountain
};

export default function RoutesPanel({ playerRep, routes }: RoutesPanelProps) {
  const routeList = Array.isArray(routes) ? routes : [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <Map size={24} className="text-red-500" />
            Race Routes
          </h2>
          <p className="text-zinc-500 text-sm mt-1">Preview routes, records, checkpoints, and access requirements</p>
        </div>
        <div className="flex items-center gap-2 text-zinc-500 text-sm shrink-0">
          <Car size={14} />
          <span>{routeList.length} routes available</span>
        </div>
      </div>

      {routeList.length === 0 ? (
        <div className="text-center text-zinc-500 py-16 border border-zinc-800 rounded-xl bg-black/30">
          <Map size={42} className="mx-auto mb-3 opacity-30" />
          <p className="text-lg">No routes loaded</p>
          <p className="text-zinc-600 text-sm mt-1">Open the tablet again after the server sends route data.</p>
        </div>
      ) : (
        <div className="space-y-5">
          {routeList.map((route, index) => {
            const locked = playerRep < route.minRep;
            const difficulty = route.difficulty || getDifficulty(route.minRep);
            const Icon = typeIcons[(route.type || 'urban') as keyof typeof typeIcons] || Building2;
            const pathPoints = route.preview && route.preview.length > 1
              ? route.preview
              : buildPreviewPath(route.checkpointCount || 5, index);

            return (
              <motion.div
                key={route.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.05 }}
                whileHover={{ scale: locked ? 1 : 1.01 }}
                className={`relative rounded-xl overflow-hidden ${locked ? 'opacity-55' : ''}`}
              >
                <div className={`route-card p-5 rounded-xl border ${locked ? 'border-zinc-800' : 'border-zinc-700 hover:border-red-900/50'} transition-all`}>
                  <div className="flex items-start justify-between mb-4 gap-4">
                    <div className="flex items-start gap-4 min-w-0">
                      <motion.div
                        whileHover={{ rotate: locked ? 0 : 5 }}
                        className={`w-16 h-16 rounded-xl flex items-center justify-center shrink-0 ${
                          locked ? 'bg-zinc-900 border border-zinc-800' : 'bg-gradient-to-br from-red-900/50 to-red-950 border border-red-900/30 shadow-lg shadow-red-900/20'
                        }`}
                      >
                        {locked ? (
                          <Lock size={26} className="text-zinc-600" />
                        ) : (
                          <Icon size={26} className="text-red-400" />
                        )}
                      </motion.div>
                      <div className="min-w-0">
                        <h3 className="text-xl font-bold text-white flex items-center gap-3">
                          <span className="truncate">{route.name}</span>
                          {locked && (
                            <span className="text-xs text-red-400 font-semibold bg-red-950/50 px-2 py-0.5 rounded border border-red-900/50 shrink-0">
                              <Lock size={10} className="inline mr-1" />
                              {route.minRep} REP REQ
                            </span>
                          )}
                        </h3>
                        <p className="text-zinc-500 text-sm max-w-md mt-1">{route.description}</p>
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <div className="text-green-400 font-bold text-2xl font-mono">${route.entryFee.toLocaleString()}</div>
                      <div className="text-zinc-600 text-xs uppercase tracking-wider">Entry Fee</div>
                    </div>
                  </div>

                  <div className="grid grid-cols-4 gap-3 mb-4">
                    <Metric icon={Flag} value={route.checkpointCount || 0} label="Checkpoints" />
                    <Metric icon={Clock} value={route.estimatedTime || estimateRouteTime(route.checkpointCount)} label="Est. Time" />
                    <div className="bg-black/50 rounded-lg p-3 text-center border border-zinc-800/50">
                      <span className={`text-sm px-3 py-1 rounded-lg border ${difficultyColors[difficulty as keyof typeof difficultyColors]}`}>
                        {difficulty}
                      </span>
                      <div className="text-zinc-600 text-xs mt-2">Difficulty</div>
                    </div>
                    <Metric icon={Gauge} value={route.minRep} label="Min Rep" />
                  </div>

                  <div className="flex flex-wrap gap-2 mb-4">
                    {(route.features && route.features.length > 0 ? route.features : getFeatures(route)).map((feature) => {
                      const isPolice = feature.toLowerCase().includes('police');
                      return (
                        <span
                          key={feature}
                          className={`text-xs px-3 py-1.5 rounded-lg border ${
                            isPolice
                              ? 'bg-red-950/30 text-red-400 border-red-900/30'
                              : 'bg-zinc-900 text-zinc-400 border-zinc-800'
                          }`}
                        >
                          {isPolice && <AlertTriangle size={10} className="inline mr-1" />}
                          {feature}
                        </span>
                      );
                    })}
                  </div>

                  <div className="h-36 bg-black/60 rounded-xl border border-zinc-800 relative overflow-hidden group">
                    <div className="absolute inset-0 opacity-10">
                      <svg className="w-full h-full">
                        <defs>
                          <pattern id={`grid-${route.id}`} width="20" height="20" patternUnits="userSpaceOnUse">
                            <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#dc2626" strokeWidth="0.5" />
                          </pattern>
                        </defs>
                        <rect width="100%" height="100%" fill={`url(#grid-${route.id})`} />
                      </svg>
                    </div>

                    <svg className="absolute inset-0 w-full h-full" viewBox="0 0 400 120" preserveAspectRatio="none">
                      <motion.path
                        d={`M ${pathPoints.map(p => p.join(',')).join(' L ')}`}
                        fill="none"
                        stroke="rgba(220, 38, 38, 0.3)"
                        strokeWidth="8"
                        strokeLinecap="round"
                        initial={{ pathLength: 0 }}
                        animate={{ pathLength: 1 }}
                        transition={{ duration: 1.4, ease: 'easeInOut' }}
                      />
                      <motion.path
                        d={`M ${pathPoints.map(p => p.join(',')).join(' L ')}`}
                        fill="none"
                        stroke="#dc2626"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeDasharray="4,4"
                        initial={{ pathLength: 0 }}
                        animate={{ pathLength: 1 }}
                        transition={{ duration: 1.1, ease: 'easeInOut' }}
                      />
                      {pathPoints.map((cp, i) => (
                        <motion.circle
                          key={`${cp[0]}-${cp[1]}-${i}`}
                          cx={cp[0]}
                          cy={cp[1]}
                          r="5"
                          fill={i === 0 ? '#22c55e' : i === pathPoints.length - 1 ? '#dc2626' : '#ffffff'}
                          stroke="#000"
                          strokeWidth="1"
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          transition={{ delay: 0.4 + i * 0.05 }}
                        />
                      ))}
                    </svg>

                    <div className="absolute bottom-2 left-3 flex items-center gap-2">
                      <div className="w-3 h-3 rounded-full bg-green-500 border border-green-400" />
                      <span className="text-zinc-500 text-xs">START</span>
                    </div>
                    <div className="absolute bottom-2 right-3 flex items-center gap-2">
                      <div className="w-3 h-3 rounded-full bg-red-500 border border-red-400" />
                      <span className="text-zinc-500 text-xs">FINISH</span>
                    </div>

                    <div className="absolute top-2 right-2 bg-black/80 border border-yellow-900/50 rounded px-2 py-1 text-right">
                      <div className="text-yellow-400 text-xs font-mono font-bold">
                        {route.record?.time ? formatTime(route.record.time) : 'No record'}
                      </div>
                      <div className="text-zinc-600 text-[10px]">{route.record?.name || 'Be first'}</div>
                    </div>
                  </div>

                  <button
                    disabled={locked}
                    onClick={() => fetchNui('createLobby', { routeId: route.id, betAmount: route.entryFee }, { success: true })}
                    className={`w-full mt-4 py-3 rounded-lg font-bold uppercase tracking-wider text-sm transition-all ${
                      locked
                        ? 'bg-zinc-900 border border-zinc-800 text-zinc-600 cursor-not-allowed'
                        : 'bg-red-950/50 border border-red-600/50 text-red-300 hover:bg-red-900/60'
                    }`}
                  >
                    {locked ? `${route.minRep} REP REQUIRED` : 'Create Race'}
                  </button>
                </div>
              </motion.div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function Metric({ icon: Icon, value, label }: { icon: typeof Flag; value: number | string; label: string }) {
  return (
    <div className="bg-black/50 rounded-lg p-3 text-center border border-zinc-800/50">
      <Icon size={16} className="mx-auto text-zinc-500 mb-1" />
      <div className="text-white font-bold text-lg">{value}</div>
      <div className="text-zinc-600 text-xs">{label}</div>
    </div>
  );
}

function getDifficulty(minRep: number) {
  if (minRep >= 150) return 'Hard';
  if (minRep >= 50) return 'Medium';
  return 'Easy';
}

function estimateRouteTime(checkpointCount = 0) {
  const seconds = Math.max(90, checkpointCount * 12);
  return `${Math.floor(seconds / 60)}:${pad2(seconds % 60)}`;
}

function formatTime(ms: number) {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  const centiseconds = Math.floor((ms % 1000) / 10);
  return `${minutes}:${pad2(seconds)}.${pad2(centiseconds)}`;
}

function pad2(value: number) {
  return value < 10 ? `0${value}` : String(value);
}

function buildPreviewPath(checkpointCount: number, routeIndex: number): Array<[number, number]> {
  const count = Math.min(10, Math.max(5, checkpointCount));
  return Array.from({ length: count }, (_, i) => {
    const x = 20 + i * (360 / (count - 1));
    const wave = Math.sin((i + routeIndex) * 1.4) * 22;
    const y = Math.max(22, Math.min(96, 60 + wave));
    return [Math.round(x), Math.round(y)] as [number, number];
  });
}

function getFeatures(route: RouteSummary) {
  const features = ['Checkpoint route'];
  if ((route.checkpointCount || 0) > 16) features.push('Endurance');
  if (route.minRep >= 150) features.push('Police Risk: High');
  else if (route.minRep >= 50) features.push('Police Risk: Medium');
  else features.push('Police Risk: Low');
  return features;
}

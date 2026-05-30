import { useEffect, useState } from 'react';
import {
  Eye,
  EyeOff,
  Monitor,
  Moon,
  RefreshCw,
  Save,
  Settings,
  ShieldAlert,
  Sun,
  ToggleLeft,
  ToggleRight
} from 'lucide-react';
import { fetchNui } from '../hooks/useNui';
import type { TabletSettings } from '../App';

interface SettingsPanelProps {
  settings: TabletSettings;
}

type ToggleKey = keyof Pick<TabletSettings, 'policeAlerts' | 'showHud'>;

const defaultSettings: TabletSettings = {
  soundEffects: true,
  notifications: true,
  policeAlerts: true,
  raceInvites: true,
  showHud: true,
  music: false,
  volume: 80,
  hudOpacity: 100,
  theme: 'dark'
};

export default function SettingsPanel({ settings }: SettingsPanelProps) {
  const [draft, setDraft] = useState<TabletSettings>({ ...defaultSettings, ...(settings || {}) });

  useEffect(() => {
    setDraft({ ...defaultSettings, ...(settings || {}) });
  }, [settings]);

  const saveSettings = (next = draft) => {
    fetchNui('saveSettings', next as unknown as Record<string, unknown>, { success: true });
  };

  const updateDraft = (next: TabletSettings, shouldSave = false) => {
    setDraft(next);
    if (shouldSave) saveSettings(next);
  };

  const toggleSetting = (id: ToggleKey) => {
    const next = { ...draft, [id]: !draft[id] };
    updateDraft(next, true);
  };

  const resetSettings = () => {
    updateDraft(defaultSettings, true);
  };

  return (
    <div className="h-full flex flex-col gap-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <Settings size={24} className="text-red-400" />
            Settings
          </h2>
          <p className="text-zinc-500 text-sm mt-1">Tablet display and race HUD controls</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={resetSettings}
            className="flex items-center gap-2 px-4 py-2 bg-zinc-800 border border-zinc-700 rounded text-zinc-400 hover:text-zinc-200 hover:border-zinc-600 transition-all"
          >
            <RefreshCw size={16} />
            Reset
          </button>
          <button
            onClick={() => saveSettings()}
            className="flex items-center gap-2 px-4 py-2 bg-red-950/50 border border-red-600/50 rounded text-red-300 hover:bg-red-900/50 transition-all"
          >
            <Save size={16} />
            Save
          </button>
        </div>
      </div>

      <div className="flex-1 grid grid-cols-2 gap-6 overflow-y-auto">
        <div className="bg-black/40 border border-zinc-800 rounded-lg p-5">
          <h3 className="text-lg font-semibold text-white flex items-center gap-2 mb-5">
            <Monitor size={18} className="text-red-400" />
            Race HUD
          </h3>

          <div className="space-y-4">
            <SettingToggle
              icon={draft.showHud ? Eye : EyeOff}
              label="Race HUD"
              enabled={draft.showHud}
              onClick={() => toggleSetting('showHud')}
            />
            <SettingToggle
              icon={ShieldAlert}
              label="Police Alerts"
              enabled={draft.policeAlerts}
              onClick={() => toggleSetting('policeAlerts')}
            />
            <div className="pt-4 border-t border-zinc-800">
              <Slider
                label="HUD Opacity"
                value={draft.hudOpacity}
                min={30}
                max={100}
                onChange={(value) => updateDraft({ ...draft, hudOpacity: value })}
                onCommit={() => saveSettings()}
              />
            </div>
          </div>
        </div>

        <div className="bg-black/40 border border-zinc-800 rounded-lg p-5">
          <h3 className="text-lg font-semibold text-white flex items-center gap-2 mb-5">
            <Settings size={18} className="text-red-400" />
            Tablet
          </h3>

          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={() => updateDraft({ ...draft, theme: 'dark' }, true)}
              className={`p-5 rounded-lg border transition-all flex flex-col items-center justify-center gap-3 ${
                draft.theme === 'dark'
                  ? 'bg-red-950/40 border-red-500/50 text-red-400'
                  : 'bg-zinc-900 border-zinc-800 text-zinc-500 hover:border-zinc-700'
              }`}
            >
              <Moon size={26} />
              <span className="font-semibold">Dark</span>
            </button>
            <button
              onClick={() => updateDraft({ ...draft, theme: 'light' }, true)}
              className={`p-5 rounded-lg border transition-all flex flex-col items-center justify-center gap-3 ${
                draft.theme === 'light'
                  ? 'bg-red-950/40 border-red-500/50 text-red-400'
                  : 'bg-zinc-900 border-zinc-800 text-zinc-500 hover:border-zinc-700'
              }`}
            >
              <Sun size={26} />
              <span className="font-semibold">Light</span>
            </button>
          </div>

          <div className="mt-5 rounded-lg border border-zinc-800 bg-zinc-950/60 p-4">
            <div className="flex items-center justify-between text-sm">
              <span className="text-zinc-500">Theme</span>
              <span className="text-red-400 font-semibold uppercase">{draft.theme}</span>
            </div>
            <div className="flex items-center justify-between text-sm mt-3">
              <span className="text-zinc-500">HUD</span>
              <span className="text-zinc-300 font-semibold">{draft.showHud ? 'Visible' : 'Hidden'}</span>
            </div>
            <div className="flex items-center justify-between text-sm mt-3">
              <span className="text-zinc-500">Alerts</span>
              <span className="text-zinc-300 font-semibold">{draft.policeAlerts ? 'Enabled' : 'Muted'}</span>
            </div>
          </div>
        </div>
      </div>

      <div className="flex items-center justify-between text-zinc-600 text-xs border-t border-zinc-800 pt-4">
        <span>Underground Racing v1.0.0</span>
        <span>BLDR street racing tablet</span>
      </div>
    </div>
  );
}

function Slider({ label, value, min, max, onChange, onCommit }: {
  label: string;
  value: number;
  min: number;
  max: number;
  onChange: (value: number) => void;
  onCommit: () => void;
}) {
  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <span className="text-zinc-300">{label}</span>
        <span className="text-red-400 font-mono">{value}%</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        onMouseUp={onCommit}
        onTouchEnd={onCommit}
        className="w-full h-2 bg-zinc-800 rounded-lg appearance-none cursor-pointer accent-red-500"
      />
    </div>
  );
}

function SettingToggle({ icon: Icon, label, enabled, onClick }: {
  icon: typeof Eye;
  label: string;
  enabled: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center justify-between p-3 bg-zinc-900/40 rounded border border-zinc-800 hover:border-zinc-700 cursor-pointer transition-all text-left"
    >
      <div className="flex items-center gap-3">
        <Icon size={18} className={enabled ? 'text-red-400' : 'text-zinc-600'} />
        <span className="text-zinc-200 font-medium">{label}</span>
      </div>
      {enabled ? (
        <ToggleRight size={24} className="text-green-400 shrink-0" />
      ) : (
        <ToggleLeft size={24} className="text-zinc-600 shrink-0" />
      )}
    </button>
  );
}

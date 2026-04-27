/**
 * Operator (Matrix Theme) — Shared Agent Types Configuration
 *
 * Centralized configuration for agent type colors, icons, and labels.
 * Used consistently across sidebar, mail, agent grid, and activity feed.
 *
 * NOTE: keys (mayor/witness/polecat/etc.) are protocol identifiers — they
 * MUST match server endpoint paths and CLI role names. Only `label` is
 * cosmetic and gets the matrix vocab swap.
 */

import { escapeHtml } from '../utils/html.js';

// Agent type configuration: protocol keys, matrix labels, matrix-palette colors.
export const AGENT_TYPES = {
  mayor:    { color: '#00FF41', icon: 'account_balance',         label: 'Architect' },
  witness:  { color: '#39FF14', icon: 'visibility',              label: 'Witness'   },
  deacon:   { color: '#39FF14', icon: 'gavel',                   label: 'Deacon'    },
  refinery: { color: '#FF003C', icon: 'precision_manufacturing', label: 'Refinery'  },
  polecat:  { color: '#00FF41', icon: 'smart_toy',               label: 'Agent'     },
  crew:     { color: '#39FF14', icon: 'groups',                  label: 'Operators' },
  human:    { color: '#00FF41', icon: 'person',                  label: 'Overseer'  },
  system:   { color: '#008F11', icon: 'settings',                label: 'System'    },
};

// Status icons for agent states
export const STATUS_ICONS = {
  idle: 'schedule',
  working: 'sync',
  waiting: 'hourglass_empty',
  error: 'error',
  complete: 'check_circle',
  running: 'play_circle',
  stopped: 'stop_circle',
};

// Status colors
export const STATUS_COLORS = {
  idle: '#6b7280',
  working: '#22c55e',
  waiting: '#f59e0b',
  error: '#ef4444',
  complete: '#22c55e',
  running: '#22c55e',
  stopped: '#6b7280',
};

/**
 * Detect agent type from agent path or role
 * @param {string} agentPath - Agent path like "rig/witness" or "mayor/"
 * @param {string} role - Optional explicit role
 * @returns {string} Agent type key
 */
export function getAgentType(agentPath, role = null) {
  // If role is explicitly provided, use it
  if (role && AGENT_TYPES[role.toLowerCase()]) {
    return role.toLowerCase();
  }

  if (!agentPath) return 'system';
  const lower = agentPath.toLowerCase();

  if (lower.includes('mayor')) return 'mayor';
  if (lower.includes('witness')) return 'witness';
  if (lower.includes('deacon')) return 'deacon';
  if (lower.includes('refinery')) return 'refinery';
  if (lower.includes('polecats/') || lower.includes('polecat')) return 'polecat';
  if (lower.includes('crew/')) return 'crew';
  if (lower === 'human' || lower === 'human/') return 'human';

  // Check if it's a polecat by name pattern (rig/name without special folders)
  const parts = agentPath.split('/');
  if (parts.length === 2 && !['mayor', 'witness', 'deacon', 'refinery'].includes(parts[1])) {
    return 'polecat'; // Likely a polecat like "rig/slit"
  }

  return 'system';
}

/**
 * Get agent config for a given path/role
 * @param {string} agentPath - Agent path
 * @param {string} role - Optional explicit role
 * @returns {Object} Agent config with color, icon, label
 */
export function getAgentConfig(agentPath, role = null) {
  const type = getAgentType(agentPath, role);
  return AGENT_TYPES[type] || AGENT_TYPES.system;
}

/**
 * Get short display name from agent path
 * @param {string} name - Full agent path like "rig/polecats/slit"
 * @returns {string} Short name like "slit"
 */
export function formatAgentName(name) {
  if (!name) return 'unknown';
  const parts = name.split('/');
  return parts[parts.length - 1] || parts[0];
}

/**
 * Create an agent badge HTML element
 * @param {string} agentPath - Agent path
 * @param {string} role - Optional explicit role
 * @param {boolean} showIcon - Whether to show the icon
 * @returns {string} HTML string for the badge
 */
export function createAgentBadge(agentPath, role = null, showIcon = true) {
  const config = getAgentConfig(agentPath, role);
  const name = formatAgentName(agentPath);

  return `<span class="agent-badge" style="--agent-color: ${config.color}">
    ${showIcon ? `<span class="material-icons">${config.icon}</span>` : ''}
    ${escapeHtml(name)}
  </span>`;
}

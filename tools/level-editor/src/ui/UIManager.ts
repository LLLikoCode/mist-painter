import type { LevelEditor } from '../editor/LevelEditor';
import type { EditorTool, PuzzleType, TileType } from '../types';
import { PUZZLE_TEMPLATES, TILE_CONFIGS } from '../config/editor.config';

/**
 * UI管理器
 * 负责编辑器界面交互和更新
 */
export class UIManager {
  private editor: LevelEditor;
  
  // DOM元素引用
  private toolButtons: Map<EditorTool, HTMLElement> = new Map();
  private propertyPanel: HTMLElement | null = null;
  private statusPosition: HTMLElement | null = null;
  private statusMessage: HTMLElement | null = null;
  
  constructor(editor: LevelEditor) {
    this.editor = editor;
  }
  
  /**
   * 初始化UI
   */
  init(): void {
    this.bindElements();
    this.bindEvents();
    this.setupPropertyPanel();
  }
  
  /**
   * 绑定DOM元素
   */
  private bindElements(): void {
    // 工具按钮
    document.querySelectorAll('.tool-btn').forEach(btn => {
      const tool = btn.getAttribute('data-tool') as EditorTool;
      if (tool) {
        this.toolButtons.set(tool, btn as HTMLElement);
      }
    });
    
    // 属性面板
    this.propertyPanel = document.getElementById('property-panel');
    
    // 状态栏
    this.statusPosition = document.getElementById('status-position');
    this.statusMessage = document.getElementById('status-message');
  }
  
  /**
   * 绑定事件
   */
  private bindEvents(): void {
    // 工具按钮点击
    this.toolButtons.forEach((btn, tool) => {
      btn.addEventListener('click', () => {
        this.editor.setTool(tool);
      });
    });
    
    // 顶部按钮
    document.getElementById('btn-new')?.addEventListener('click', () => {
      this.editor.newLevel();
    });
    
    document.getElementById('btn-open')?.addEventListener('click', () => {
      this.openFileDialog();
    });
    
    document.getElementById('btn-save')?.addEventListener('click', () => {
      this.editor.saveLevel();
    });
    
    document.getElementById('btn-export')?.addEventListener('click', () => {
      this.showExportDialog();
    });
    
    // 监听编辑器事件
    this.editor.on('tool:changed', (data) => {
      this.updateToolSelection(data.tool);
      this.updatePropertyPanel();
    });
    
    this.editor.on('canvas:mousemove', (data) => {
      this.updatePositionStatus(data.position);
    });
    
    this.editor.on('selection:changed', () => {
      this.updatePropertyPanel();
    });
    
    this.editor.on('level:saved', (data) => {
      this.showMessage('已保存: ' + data.path);
    });
    
    this.editor.on('level:exported', (data) => {
      this.showMessage('已导出: ' + data.path);
    });
  }
  
  /**
   * 设置属性面板
   */
  private setupPropertyPanel(): void {
    if (!this.propertyPanel) return;
    
    this.updatePropertyPanel();
  }
  
  /**
   * 更新属性面板
   */
  updatePropertyPanel(): void {
    if (!this.propertyPanel) return;
    
    const tool = this.editor.getCurrentTool();
    const selection = this.editor.getSelectedObject();
    
    let html = '';
    
    // 根据当前工具显示不同内容
    switch (tool) {
      case 'terrain':
        html = this.renderTerrainPanel();
        break;
      case 'puzzle':
        html = this.renderPuzzlePanel();
        break;
      case 'mist':
        html = this.renderMistPanel();
        break;
      default:
        if (selection) {
          html = this.renderSelectionPanel(selection);
        } else {
          html = this.renderLevelInfoPanel();
        }
    }
    
    this.propertyPanel.innerHTML = html;
    
    // 绑定面板内事件
    this.bindPanelEvents();
  }
  
  /**
   * 渲染地形面板
   */
  private renderTerrainPanel(): string {
    let html = `
      <div class="property-group">
        <h3>图块选择</h3>
        <div class="tile-palette">
    `;
    
    for (const tile of TILE_CONFIGS) {
      const selected = this.editor.getSelectedTileType() === tile.type ? 'selected' : '';
      html += `
        <div class="tile-item ${selected}" data-tile-type="${tile.type}" title="${tile.name}">
          <span style="color: ${tile.color}">${tile.icon}</span>
        </div>
      `;
    }
    
    html += '</div></div>';
    
    // 图层选择
    html += `
      <div class="property-group">
        <h3>图层</h3>
        <div class="property-row">
          <label>当前层</label>
          <select id="layer-select">
            <option value="floor">地板层</option>
            <option value="walls">墙壁层</option>
            <option value="decorations">装饰层</option>
          </select>
        </div>
      </div>
    `;
    
    return html;
  }
  
  /**
   * 渲染谜题面板
   */
  private renderPuzzlePanel(): string {
    let html = `
      <div class="property-group">
        <h3>谜题类型</h3>
        <div class="puzzle-type-list">
    `;
    
    for (const template of PUZZLE_TEMPLATES) {
      const selected = this.editor.getSelectedPuzzleType() === template.type ? 'selected' : '';
      html += `
        <div class="puzzle-type-item ${selected}" data-puzzle-type="${template.type}">
          <div style="font-size: 20px; margin-bottom: 4px;">${template.icon}</div>
          <div style="font-weight: 600;">${template.name}</div>
          <div style="font-size: 11px; color: #888; margin-top: 4px;">${template.description}</div>
        </div>
      `;
    }
    
    html += '</div></div>';
    return html;
  }
  
  /**
   * 渲染迷雾面板
   */
  private renderMistPanel(): string {
    return `
      <div class="property-group">
        <h3>笔刷设置</h3>
        <div class="property-row">
          <label>笔刷大小</label>
          <input type="range" id="brush-size" min="10" max="100" value="${this.editor.getBrushSize()}">
        </div>
        <div class="property-row">
          <label>迷雾密度</label>
          <input type="range" id="mist-density" min="0" max="100" value="95">
        </div>
      </div>
      <div class="property-group">
        <h3>操作</h3>
        <button class="btn btn-secondary" id="btn-fill-all" style="width: 100%; margin-bottom: 8px;">填充全部迷雾</button>
        <button class="btn btn-secondary" id="btn-clear-all" style="width: 100%;">清除全部迷雾</button>
      </div>
    `;
  }
  
  /**
   * 渲染选中对象面板
   */
  private renderSelectionPanel(selection: { type: string; data: Record<string, unknown> }): string {
    const data = selection.data;
    
    let html = `
      <div class="property-group">
        <h3>选中对象</h3>
        <div class="property-row">
          <label>类型</label>
          <input type="text" value="${selection.type}" readonly>
        </div>
    `;
    
    if (data.id) {
      html += `
        <div class="property-row">
          <label>ID</label>
          <input type="text" value="${data.id}" readonly>
        </div>
      `;
    }
    
    if (data.name) {
      html += `
        <div class="property-row">
          <label>名称</label>
          <input type="text" id="prop-name" value="${data.name}">
        </div>
      `;
    }
    
    if (data.position) {
      const pos = data.position as { x: number; y: number };
      html += `
        <div class="property-row">
          <label>位置 X</label>
          <input type="number" id="prop-x" value="${Math.round(pos.x)}">
        </div>
        <div class="property-row">
          <label>位置 Y</label>
          <input type="number" id="prop-y" value="${Math.round(pos.y)}">
        </div>
      `;
    }
    
    html += `
        <div class="property-row" style="margin-top: 16px;">
          <button class="btn btn-primary" id="btn-update-prop" style="flex: 1;">更新</button>
          <button class="btn btn-secondary" id="btn-delete-prop" style="flex: 1; margin-left: 8px;">删除</button>
        </div>
      </div>
    `;
    
    return html;
  }
  
  /**
   * 渲染关卡信息面板
   */
  private renderLevelInfoPanel(): string {
    const levelData = this.editor.getLevelData();
    return `
      <div class="property-group">
        <h3>关卡信息</h3>
        <div class="property-row">
          <label>关卡ID</label>
          <input type="text" value="${levelData.metadata.id}" readonly>
        </div>
        <div class="property-row">
          <label>关卡名称</label>
          <input type="text" id="level-name" value="${levelData.metadata.name}">
        </div>
        <div class="property-row">
          <label>描述</label>
          <input type="text" id="level-desc" value="${levelData.metadata.description || ''}">
        </div>
        <div class="property-row">
          <label>作者</label>
          <input type="text" id="level-author" value="${levelData.metadata.author || ''}">
        </div>
        <div class="property-row">
          <label>版本</label>
          <input type="text" value="${levelData.metadata.version}" readonly>
        </div>
      </div>
      <div class="property-group">
        <h3>统计</h3>
        <div class="property-row">
          <label>网格尺寸</label>
          <input type="text" value="${levelData.gridSize.width}x${levelData.gridSize.height}" readonly>
        </div>
        <div class="property-row">
          <label>谜题数量</label>
          <input type="text" value="${levelData.puzzles.length}" readonly>
        </div>
        <div class="property-row">
          <label>迷雾区域</label>
          <input type="text" value="${levelData.mist.zones.length}" readonly>
        </div>
      </div>
    `;
  }
  
  /**
   * 绑定面板事件
   */
  private bindPanelEvents(): void {
    // 图块选择
    document.querySelectorAll('.tile-item').forEach(item => {
      item.addEventListener('click', () => {
        const tileType = parseInt(item.getAttribute('data-tile-type') || '0');
        this.editor.setSelectedTileType(tileType);
        this.updatePropertyPanel();
      });
    });
    
    // 谜题类型选择
    document.querySelectorAll('.puzzle-type-item').forEach(item => {
      item.addEventListener('click', () => {
        const puzzleType = item.getAttribute('data-puzzle-type') as PuzzleType;
        this.editor.setSelectedPuzzleType(puzzleType);
        this.updatePropertyPanel();
      });
    });
    
    // 笔刷大小
    const brushSizeInput = document.getElementById('brush-size') as HTMLInputElement;
    if (brushSizeInput) {
      brushSizeInput.addEventListener('input', () => {
        this.editor.setBrushSize(parseInt(brushSizeInput.value));
      });
    }
    
    // 迷雾操作
    document.getElementById('btn-fill-all')?.addEventListener('click', () => {
      // 获取迷雾编辑器并填充
      // this.editor.getMistEditor().fillAllMist();
    });
    
    document.getElementById('btn-clear-all')?.addEventListener('click', () => {
      // this.editor.getMistEditor().clearAllMist();
    });
  }
  
  /**
   * 更新工具选择状态
   */
  private updateToolSelection(tool: EditorTool): void {
    this.toolButtons.forEach((btn, t) => {
      btn.classList.toggle('active', t === tool);
    });
  }
  
  /**
   * 更新位置状态
   */
  private updatePositionStatus(position: { x: number; y: number }): void {
    if (this.statusPosition) {
      this.statusPosition.textContent = `位置: ${Math.round(position.x)}, ${Math.round(position.y)}`;
    }
  }
  
  /**
   * 显示消息
   */
  private showMessage(message: string): void {
    if (this.statusMessage) {
      this.statusMessage.textContent = message;
      setTimeout(() => {
        if (this.statusMessage) {
          this.statusMessage.textContent = '就绪';
        }
      }, 3000);
    }
  }
  
  /**
   * 打开文件对话框
   */
  private openFileDialog(): void {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (file) {
        const reader = new FileReader();
        reader.onload = (event) => {
          try {
            const data = JSON.parse(event.target?.result as string);
            this.editor.loadLevel(data);
          } catch (err) {
            alert('无效的关卡文件');
          }
        };
        reader.readAsText(file);
      }
    };
    input.click();
  }
  
  /**
   * 显示导出对话框
   */
  private showExportDialog(): void {
    const format = confirm('导出为TSCN格式？\n确定: TSCN (Godot场景)\n取消: JSON') ? 'tscn' : 'json';
    this.editor.exportLevel(format);
  }
}
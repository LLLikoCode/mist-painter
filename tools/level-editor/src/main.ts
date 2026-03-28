import { LevelEditor } from './editor/LevelEditor';
import { UIManager } from './ui/UIManager';
import type { EditorTool, PuzzleType, TileType } from './types';

/**
 * 编辑器应用主入口
 */
class EditorApp {
  private editor: LevelEditor;
  private ui: UIManager;
  
  constructor() {
    this.editor = new LevelEditor();
    this.ui = new UIManager(this.editor);
  }
  
  /**
   * 初始化应用
   */
  init(): void {
    // 初始化Phaser编辑器
    this.editor.init('game-canvas');
    
    // 初始化UI
    this.ui.init();
    
    // 设置全局快捷键
    this.setupKeyboardShortcuts();
    
    console.log('迷雾绘者 - 谜题编辑器已启动');
  }
  
  /**
   * 设置键盘快捷键
   */
  private setupKeyboardShortcuts(): void {
    document.addEventListener('keydown', (e) => {
      // 数字键切换工具
      if (!e.ctrlKey && !e.metaKey) {
        switch (e.key) {
          case '1':
            this.editor.setTool('select');
            break;
          case '2':
            this.editor.setTool('terrain');
            break;
          case '3':
            this.editor.setTool('puzzle');
            break;
          case '4':
            this.editor.setTool('mist');
            break;
          case '5':
            this.editor.setTool('eraser');
            break;
        }
      }
    });
  }
}

// 启动应用
document.addEventListener('DOMContentLoaded', () => {
  const app = new EditorApp();
  app.init();
});

// 导出供外部使用
export { LevelEditor, UIManager };
export * from './types';
export * from './config/editor.config';

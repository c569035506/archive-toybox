请根据以下模拟对话，生成复盘评分。

设定：
- 对方：{{opponent_label}}
- 关系：{{relationship}}
- 事件：{{what_happened}}
- 练习目标：{{practice_goal}}

对话：
{{conversation}}

输出 JSON：
{
  "scores": {
    "emotional_stability": 1-5,
    "boundary_expression": 1-5,
    "logic_clarity": 1-5,
    "anti_frame_control": 1-5,
    "relationship_preservation": 1-5,
    "effective_response": 1-5
  },
  "title": "称号，8字以内",
  "summary": "复盘摘要",
  "highlights": ["做得好的点"],
  "suggestions": ["可改进点"],
  "best_quote": "用户本局最佳表达"
}

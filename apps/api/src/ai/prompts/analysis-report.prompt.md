请分析以下聊天记录，帮助用户理解冲突并改进表达。

用户是：{{self_side}}
双方关系：{{relationship}}
分析目标：{{analysis_goal}}

聊天记录：
{{chat_text}}

输出 JSON，字段如下：
{
  "one_liner": "一句话总结",
  "root_cause": "争吵起因",
  "escalation_points": "情绪升级点",
  "expression_patterns": "双方表达模式",
  "user_strengths": "用户说得好的地方",
  "user_improvements": "用户可以优化的地方",
  "better_phrasing": "更好的表达版本",
  "next_reply": "下一句怎么回",
  "final_advice": "最终建议"
}

要求：建议具体、可执行，不煽动冲突，不输出攻击性或 PUA 内容。

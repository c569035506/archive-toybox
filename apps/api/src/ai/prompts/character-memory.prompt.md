你将维护一个「吵架练习角色」的跨场次记忆摘要，帮助 AI 在下次扮演该角色时保持一致。

角色设定：
- 称呼：{{character_name}}
- 关系：{{relationship}}
- 说话风格：{{opponent_style}}
- 身份：{{opponent_identity_desc}}
- 性格：{{opponent_personality_desc}}

已有记忆（可能为空）：
{{existing_memory}}

本次练习对话：
{{conversation}}

请输出 JSON：{"memory_summary":"..."}

要求：
1. 在已有记忆基础上更新，保留仍重要的性格表现、说话习惯、情绪触发点、与用户的关系张力
2. 融入本次对话中新暴露的态度、底线、惯用话术，但不要逐句复述聊天记录
3. 用第三人称描述该角色，1500 字以内，条目感清晰，便于下次扮演时快速理解
4. 若已有记忆为空，则根据本次对话提炼首版角色记忆
5. 不要输出 JSON 以外的任何文字

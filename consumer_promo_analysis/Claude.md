CLAUDE.md  
Behavioral guidelines to enhance productivity and reduce common pitfalls in data analysis, with attention to SQL and numerical validation. Merge with specific project instructions as needed.

**Tradeoff:** These guidelines prioritize accuracy and clarity over speed. For routine tasks, apply your judgment.

1. **Understand Before Analyzing**  
   Avoid assumptions. Clearly express uncertainties. Highlight trade-offs.

   Before diving into data analysis:

   - Clearly state your assumptions. If unsure, seek clarification.
   - Present all plausible interpretations and alternative methods; do not choose one without discussion.
   - Suggest simpler alternatives if they exist. Challenge excessive complexity.
   - If something is unclear, pause. Clearly articulate confusion and ask questions.

2. **Simplicity and Clarity**  
   Focus on essential analysis. Avoid adding unnecessary complexity.

   - Only conduct analyses specifically requested or necessary.
   - Avoid complex models or queries for simple analysis when straightforward methods suffice.
   - Do not generate insights for data or parameters not asked for.
   - Use simple SQL queries for retrieval unless specific complexity is needed. Prefer JOINs and WHERE clauses strategically to simplify analysis.
   - If an analysis can be summarized more concisely, revise it.
   - Ask yourself: "Would a senior data scientist or engineer find this overly complex?" If so, simplify.

3. **Precision in Execution**  
   Modify and analyze only what is necessary. Clean up only your own errors.

   During data analysis:

   - Do not "improve" unrelated datasets or SQL queries.
   - Avoid excessively optimizing SQL queries that perform adequately.
   - Maintain existing formatting and styles, even if you'd prefer changes.
   - If you find unrelated data anomalies or outliers, note them but don’t address them unless relevant to your task.
   - Ensure calculations and numerical validations are precise and checked against expected thresholds or benchmarks.

4. **Goal-Oriented Analysis**  
   Define success criteria. Verify iteratively.

   Transform tasks into attainable goals:

   - "Explore correlations" → "Identify key correlations between variables A and B and validate their significance"
   - "Clean data" → "Identify and correct inconsistencies or errors, then validate with tests, possibly through SQL queries"
   - "Build a predictive model" → "Develop a model, test its accuracy, and iterate based on results"
   - "Validate data" → "Use SQL to confirm aggregate figures match source data specifications"

   For multi-step tasks, outline a concise plan:

   1. [Step] → verify: [check]
   2. [Step] → verify: [check]
   3. [Step] → verify: [check]

   Strong success criteria allow for autonomous iteration. Weak criteria ("make sense of the data") require ongoing clarification.

These guidelines are successful if there are fewer unnecessary analyses, fewer re-analyses due to overcomplication, and questions for clarification come before executing an analysis rather than after overlooking something.
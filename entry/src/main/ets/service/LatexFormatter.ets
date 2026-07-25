export class LatexFormatter {
  static format(source: string): string {
    let result: string = source.trim();
    result = result.replace(new RegExp('\\\\sqrt\\{([^{}]*)\\}', 'g'), 'sqrt($1)');
    for (let index: number = 0; index < 4; index += 1) {
      result = result.replace(new RegExp('\\\\frac\\{([^{}]*)\\}\\{([^{}]*)\\}', 'g'), '($1)/($2)');
    }
    result = result.replace(new RegExp('\\\\left|\\\\right', 'g'), '');
    result = result.replace(new RegExp('\\\\times', 'g'), 'x').replace(new RegExp('\\\\cdot', 'g'), '*').replace(new RegExp('\\\\pm', 'g'), '+/-');
    result = result.replace(new RegExp('\\\\leq?|\\\\le', 'g'), '<=').replace(new RegExp('\\\\geq?|\\\\ge', 'g'), '>=').replace(new RegExp('\\\\neq|\\\\ne', 'g'), '!=').replace(new RegExp('\\\\rightarrow|\\\\to', 'g'), '->');
    result = result.replace(new RegExp('\\\\infty', 'g'), 'infinity').replace(new RegExp('\\\\sum', 'g'), 'sum').replace(new RegExp('\\\\int', 'g'), 'integral').replace(new RegExp('\\\\lim', 'g'), 'lim');
    result = result.replace(new RegExp('\\\\sin|\\\\cos|\\\\tan|\\\\log|\\\\ln', 'g'), (value: string): string => value.slice(1)).replace(new RegExp('\\\\quad|\\\\,|\\\\;', 'g'), ' ');
    result = result.replace(new RegExp('\\\\alpha', 'g'), 'alpha').replace(new RegExp('\\\\beta', 'g'), 'beta').replace(new RegExp('\\\\gamma', 'g'), 'gamma').replace(new RegExp('\\\\delta', 'g'), 'delta').replace(new RegExp('\\\\theta', 'g'), 'theta').replace(new RegExp('\\\\lambda', 'g'), 'lambda').replace(new RegExp('\\\\mu', 'g'), 'mu').replace(new RegExp('\\\\pi', 'g'), 'pi').replace(new RegExp('\\\\sigma', 'g'), 'sigma').replace(new RegExp('\\\\phi', 'g'), 'phi').replace(new RegExp('\\\\omega', 'g'), 'omega');
    result = result.replace(new RegExp('\\^\\{([^{}]+)\\}', 'g'), '^($1)').replace(new RegExp('_\\{([^{}]+)\\}', 'g'), '_($1)');
    result = result.replace(new RegExp('[{}]', 'g'), '');
    result = result.replace(new RegExp('\\^2', 'g'), '²').replace(new RegExp('\\^3', 'g'), '³').replace(new RegExp('\\^0', 'g'), '⁰').replace(new RegExp('\\^1', 'g'), '¹');
    return result;
  }
}

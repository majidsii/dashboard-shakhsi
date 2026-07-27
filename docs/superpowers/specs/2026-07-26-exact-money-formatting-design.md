# Exact Money Formatting Design

## Goal

All finance inputs and outputs must use one exact monetary representation with live thousands grouping and up to eight fractional digits.

## Data representation

- Monetary values use fixed-point integers with scale `8`.
- `1 تومان` is stored as `100000000` minor units.
- No persisted or calculated monetary value uses `double`.
- Existing `Money` arithmetic remains currency- and scale-safe.
- Chart painters may receive a `double` projection solely for drawing coordinates; labels and totals always use the exact value.

## Input behavior

- Accept Persian, Arabic, and Latin digits.
- Accept `.` and `٫` as decimal separators.
- Ignore `,`, `٬`, and spaces used as grouping separators.
- Allow at most eight fractional digits.
- Apply grouping live while typing.
- Render input as Persian digits with `٬` for grouping and `٫` for decimals.
- Preserve a trailing decimal separator and trailing fractional zeros while the user is editing.
- Keep the caret at the same logical digit position when separators are inserted or removed.
- Amount fields accept decimals; installment count fields remain integer-only.

## Output behavior

- Use Persian digits everywhere.
- Group the integer part in threes.
- Show up to eight fractional digits.
- Remove unnecessary trailing fractional zeros in read-only output.
- Keep transaction signs separate from the amount.
- Use `تومان` consistently.

## Validation

- Amounts must be greater than zero when creating entries or payments.
- Paid debt amounts are clamped exactly between zero and the debt total.
- Values with more than eight fractional digits are rejected by parsing and prevented by the formatter.
- Values outside the signed 64-bit fixed-point range are rejected rather than silently rounded or overflowed.

## Scope

This stage updates the in-memory finance preview, all finance form amount fields, summaries, transaction rows, debt/installment rows, and charts. Database persistence remains a later stage.

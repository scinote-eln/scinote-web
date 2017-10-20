// @flow

export function transformName(name: string ): string {
  return name ? name.replace(/\s+/g, "-").toLowerCase() : ""
}

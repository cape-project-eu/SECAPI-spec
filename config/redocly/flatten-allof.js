const RE_TILDE1 = /~1/g;
const RE_TILDE0 = /~0/g;
const RE_REF_PREFIX = /^#\//;

function resolveRef(ref, root) {
  const path = ref.replace(RE_REF_PREFIX, '').split('/');
  let node = root;
  for (const segment of path) {
    node = node?.[segment.replace(RE_TILDE1, '/').replace(RE_TILDE0, '~')];
  }
  return node;
}

function isPlainObject(v) {
  return v !== null && typeof v === 'object' && !Array.isArray(v);
}

function syntheticExampleValue(propSchema, root, depth = 0) {
  if (!propSchema || depth > 5) return undefined;
  if (propSchema.example !== undefined) return propSchema.example;
  if (propSchema.default !== undefined) return propSchema.default;
  if (Array.isArray(propSchema.enum) && propSchema.enum.length > 0) return propSchema.enum[0];

  if (propSchema.$ref) {
    return syntheticExampleValue(resolveRef(propSchema.$ref, root), root, depth + 1);
  }

  switch (propSchema.type) {
    case 'string':
      if (propSchema.format === 'date-time') return '2024-01-01T00:00:00Z';
      if (propSchema.format === 'date')      return '2024-01-01';
      if (propSchema.format === 'uuid')      return '00000000-0000-0000-0000-000000000000';
      return 'string';
    case 'integer':
    case 'number':  return propSchema.minimum ?? 0;
    case 'boolean': return false;
    case 'array':   return [];
    case 'object': {
      if (!isPlainObject(propSchema.properties)) return {};
      const example = {};
      const required = Array.isArray(propSchema.required) ? propSchema.required : [];
      for (const field of required) {
        const val = syntheticExampleValue(propSchema.properties[field], root, depth + 1);
        if (val !== undefined) example[field] = val;
      }
      return example;
    }
    default: return undefined;
  }
}

function mergeSchemas(schemas) {
  const result = {};
  const properties = {};
  const required = new Set();
  let example;

  for (const schema of schemas) {
    if (!schema || typeof schema !== 'object') continue;
    for (const [key, value] of Object.entries(schema)) {
      if (key === 'properties') {
        Object.assign(properties, value);
      } else if (key === 'required' && Array.isArray(value)) {
        for (const item of value) required.add(item);
      } else if (key === 'example') {
        if (isPlainObject(value)) {
          example = { ...(isPlainObject(example) ? example : {}), ...value };
        } else if (example === undefined) {
          example = value;
        }
      } else if (!(key in result)) {
        result[key] = value;
      }
    }
  }

  const propKeys = Object.keys(properties);
  if (propKeys.length > 0) result.properties = properties;
  if (required.size > 0) result.required = [...required];
  if (!result.type && propKeys.length > 0) result.type = 'object';
  if (example !== undefined) result.example = example;

  return result;
}

module.exports = function flattenAllOfPlugin() {
  return {
    id: 'flatten-allof',
    decorators: {
      oas3: {
        'flatten-all-of': FlattenAllOf,
      },
    },
  };
};

function FlattenAllOf() {
  let root = null;

  return {
    Root: {
      enter(rootNode) {
        root = rootNode;
      },
    },
    Schema: {
      leave(schema) {
        if (!('allOf' in schema)) return;

        const resolvedSubSchemas = schema.allOf.map(item =>
          item.$ref ? resolveRef(item.$ref, root) ?? item : item
        );

        const { allOf, ...parentFields } = schema;
        const merged = mergeSchemas(resolvedSubSchemas);
        const result = { ...merged, ...parentFields };

        if (isPlainObject(merged.example) && isPlainObject(parentFields.example)) {
          result.example = { ...merged.example, ...parentFields.example };
        }

        if (Array.isArray(result.required) && isPlainObject(result.properties)) {
          const example = isPlainObject(result.example) ? { ...result.example } : {};
          for (const field of result.required) {
            const propSchema = result.properties[field];
            if (!propSchema) continue;
            const current = example[field];
            const isEmptyPlaceholder = isPlainObject(current) && Object.keys(current).length === 0;
            if (!(field in example) || isEmptyPlaceholder) {
              const val = syntheticExampleValue(propSchema, root);
              if (val !== undefined) example[field] = val;
            }
          }
          if (Object.keys(example).length > 0) result.example = example;
        }

        for (const key of Object.keys(schema)) delete schema[key];
        Object.assign(schema, result);
      },
    },
  };
}

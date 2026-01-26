# std.Io.SelectUnion

Given a struct with each field a `*Future`, returns a union with the same fields, each field type the future's result.

## Parameters

    S: type

## Source Code

```
pub fn SelectUnion(S: type) type {
    const struct_fields = @typeInfo(S).@"struct".fields;
    var names: [struct_fields.len][]const u8 = undefined;
    var types: [struct_fields.len]type = undefined;
    for (struct_fields, &names, &types) |struct_field, *union_field_name, *UnionFieldType| {
        const FieldFuture = @typeInfo(struct_field.type).pointer.child;
        union_field_name.* = struct_field.name;
        UnionFieldType.* = @FieldType(FieldFuture, "result");
    }
    return @Union(.auto, std.meta.FieldEnum(S), &names, &types, &@splat(.{}));
}
```

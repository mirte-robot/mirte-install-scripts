def copy_on_modify(pathA, pathB):
    def copy_function(src_path):
        # otherwise it is triggering itself. 1s backoff time
        copy_function.src_path = src_path

    copy_function.src_path = 3
    return copy_function


a = copy_on_modify("a.txt", "b.txt")
b = copy_on_modify("b.txt", "a.txt")
print(a.src_path)
print(b.src_path)

a("a.txt")
print(a.src_path)
print(b.src_path)
b("b.txt")
print(a.src_path)
print(b.src_path)

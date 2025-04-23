import sys
#import numpy

the_modules_and_globals=None

def eval_string(s):
    global the_modules_and_globals
    global_vars = the_modules_and_globals
    local_vars = locals()
    return eval(s,global_vars,local_vars)

def exec_string(s):
    global the_modules_and_globals
    global_vars = the_modules_and_globals
    local_vars = locals()
    return exec(s,global_vars,local_vars)

def py_nth(s,nth):
    return s[nth]

def identity(s):
    return s

def get_globals():
    return globals()

def hello_plus(atom1, atom2):
    print("hello",type(atom1),type(atom2))
    return []

def merge_modules_and_globals():
    # Get all currently loaded modules
    loaded_modules = sys.modules

    # Get all global variables
    global_vars = globals()

    # Prepare a combined dictionary
    global the_modules_and_globals
    combined_dict = the_modules_and_globals
    if combined_dict is None:
        combined_dict = {}

    # Add modules with a prefix or special key to distinguish them
    for mod_name, mod_obj in loaded_modules.items():
        combined_dict[f"module_{mod_name}"] = mod_obj
        combined_dict[f"{mod_name}"] = mod_obj

    # Add global variables with a prefix or special key
    for var_name, var_value in global_vars.items():
        combined_dict[f"global_{var_name}"] = var_value
        combined_dict[f"{var_name}"] = var_value

    the_modules_and_globals = combined_dict
    return combined_dict

def get_locals():
    return locals()

def iter_collection(s):
    return iter(s)

def string_conversion(s):
    return str(s)

def string_representation(s):
    return repr(s)

def py_len(s):
    return len(s)

def py_list(s):
    return list(s)

def py_dict(s):
    return dict(s)

def py_dict0():
    return dict()

def py_map(s):
    return map(s)

def py_tuple(s):
    return tuple(s)

def py_set(s):
    return set(s)

def absolute_value(num):
    return abs(num)

def all_true(iterable):
    return all(iterable)

def any_true(iterable):
    return any(iterable)

def as_ascii(s):
    return ascii(s)

def binary_conversion(num):
    return bin(num)

def boolean_conversion(val):
    return bool(val)

def chr_conversion(num):
    return chr(num)

def hexadecimal_conversion(num):
    return hex(num)

def octal_conversion(num):
    return oct(num)

# Arithmetic and Conversion
def int_conversion(s):
    return int(s)

def float_conversion(s):
    return float(s)

def complex_conversion(real, imag=0):
    return complex(real, imag)

def divmod_func(a, b):
    return divmod(a, b)

def pow_func(base, exp):
    return pow(base, exp)

# Collection Handling
def sorted_iterable(iterable, key=None, reverse=False):
    return sorted(iterable, key=key, reverse=reverse)

def sum_iterable(iterable, start=0):
    return sum(iterable, start)

def min_value(*args, key=None):
    return min(*args, key=key)

def max_value(*args, key=None):
    return max(*args, key=key)

# Type and Attribute Handling
def type_of(obj):
    return type(obj)

def isinstance_of(obj, classinfo):
    return isinstance(obj, classinfo)

def print_nonl(sub):
    return print(sub, end="")

def issubclass_of(sub, superclass):
    return issubclass(sub, superclass)

def getattr_func(obj, name, default=None):
    return getattr(obj, name, default)

def setattr_func(obj, name, value):
    setattr(obj, name, value)

def hasattr_func(obj, name):
    return hasattr(obj, name)

# File and I/O
def open_file(filename, mode="r", buffering=-1):
    return open(filename, mode, buffering)

# Exception Handling
def raise_exception(exctype, msg=None):
    if msg:
        raise exctype(msg)
    else:
        raise exctype()

# Miscellaneous
def callable_check(obj):
    return callable(obj)

def id_func(obj):
    return id(obj)

def help_func(obj):
    help(obj)  # This will print the help to the standard output

import inspect

def get_str_rep(func):
    if not inspect.isfunction(func):
        return func
    if func.__module__ == "__main__":
        return func.__name__
    return f"{func.__module__}.{func.__name__}"

DEBUG_MODE = False  # Set this to True to enable debug output

import importlib
import types
import time

def py_call_method_and_args(*method_and_args):
    """
    Calls a Python callable (function, method, or constructor) with the provided arguments.

    This function is designed to handle various cases of invocation, including:
    - Bound methods.
    - Function or method name as a string with an instance.
    - Class and method name as a string.
    - Object and method name as a string.
    - Unbound methods with an instance.
    - Other callable objects.

    Args:
        *method_and_args: A variable-length argument list that includes:
            - The callable or something that resolves to a callable (e.g., "time.time" or "some_instance.my_method").
            - Any subsequent positional or keyword-like arguments to pass to the callable.

    Returns:
        The result of the callable invocation.

    Raises:
        ValueError: If no callable is provided.
        TypeError: If the callable cannot be invoked.
        AttributeError: If the method does not exist on the given class or instance.
    """
    # --------------------------------------------------
    # CASE 0: Unwrap if the single argument is a list/tuple
    # --------------------------------------------------
    # If the user calls py_call_method_and_args with a single argument that
    # itself is a list or tuple, we 'unpack' it so that *method_and_args
    # becomes multiple items. Example:
    #
    #   py_call_method_and_args([some_callable, arg1, arg2])
    #
    # becomes effectively:
    #
    #   some_callable, arg1, arg2
    #
    # inside this function.
    # --------------------------------------------------
    if len(method_and_args) == 1 and isinstance(method_and_args[0], (list, tuple)):
        # Unpack the single list or tuple argument
        method_and_args = method_and_args[0]

    # --------------------------------------------------
    # Make sure we actually got something to call
    # --------------------------------------------------
    if not method_and_args:
        raise ValueError("No callable provided to invoke.")

    # handle case like py_call_method_and_args([time.time])
    if len(method_and_args) == 1 and callable(method_and_args[0]):
        return method_and_args[0]()  # Call the single callable without arguments

    # --------------------------------------------------
    # Extract the first element from method_and_args,
    # which should be our potential callable or something
    # that leads us to a callable.
    # --------------------------------------------------   
    callable_obj, *args = method_and_args

    # ==================================================
    # CASE 1: Bound Method
    # ==================================================
    # In Python, a 'bound method' is typically a function that has its __self__
    # attribute set to an instance. For example:
    #
    #   instance.my_method
    #
    # is a bound method of 'instance'.
    #
    # We can check if it's a bound method by verifying it's callable and has
    # a non-None __self__. Then, we can directly call it with whatever arguments
    # come after.
    # ==================================================
    if (
        callable(callable_obj) and
        hasattr(callable_obj, '__self__') and
        callable_obj.__self__ is not None
    ):
        return py_call_w_args(callable_obj, *args)

    # ==================================================
    # CASE 2: Function/Method Name (str) + an Instance
    # ==================================================
    # If the first item is a string, and the second item in 'args' is some object,
    # then maybe the user is calling something like:
    #
    #   py_call_method_and_args("method_name", instance, arg1, arg2, ...)
    #
    # We interpret that to mean "call instance.method_name(*arg1, *arg2, ...)".
    # ==================================================
    if isinstance(callable_obj, str) and len(args) > 0:
        method_name = callable_obj      # The string representing the method/function name
        instance = args[0]             # The object on which we're calling the method
        method_args = args[1:]         # The rest of the arguments to pass

        # Retrieve the method from the instance by name
        method = getattr(instance, method_name, None)

        # If the method doesn't exist or isn't callable, raise an error
        if method is None or not callable(method):
            raise AttributeError(f"The instance has no callable method named '{method_name}'.")

        # Invoke the method via py_call_w_args
        return py_call_w_args(method, *method_args)

    # ==================================================
    # CASE 3: Class + Single Arg => Construct Instance
    # ==================================================
    # If the first item is a class/type, and there's exactly 1 argument following,
    # we interpret that as calling the class constructor with that single argument.
    # For example:
    #
    #   py_call_method_and_args(SomeClass, 'hi')
    #
    # means do:
    #
    #   SomeClass('hi')
    # ==================================================
    if isinstance(callable_obj, type) and len(args) == 1:
        return callable_obj(args[0])

    # ==================================================
    # CASE 3A: Class + Method Name (str) => Call Class Method
    # ==================================================
    # If the first item is a class, and the second item in 'args' is a string,
    # we interpret that as:
    #
    #   py_call_method_and_args(SomeClass, "method_name", arg1, arg2, ...)
    #
    # meaning:
    #
    #   SomeClass.method_name(arg1, arg2, ...)
    # ==================================================
    if isinstance(callable_obj, type) and len(args) > 0 and isinstance(args[0], str):
        cls = callable_obj
        method_name = args[0]
        method_args = args[1:]

        # Retrieve the method from the class by name
        method = getattr(cls, method_name, None)
        if method is None or not callable(method):
            raise AttributeError(f"The class '{cls.__name__}' has no callable method named '{method_name}'.")

        # Call that method via py_call_w_args
        return py_call_w_args(method, *method_args)

    # ==================================================
    # CASE 4: Object + Method Name (str)
    # ==================================================
    # If we have something like:
    #
    #   py_call_method_and_args(obj, "method_name", arg1, arg2, ...)
    #
    # we interpret that as calling 'obj.method_name(arg1, arg2, ...)'.
    # ==================================================
    if (
        len(method_and_args) > 1 and
        isinstance(method_and_args[0], object) and
        isinstance(method_and_args[1], str)
    ):
        obj = method_and_args[0]       # The object
        method_name = method_and_args[1]  # The string name of the method
        new_args = method_and_args[2:]    # The rest of the arguments

        # Attempt to retrieve the method from the object
        method = getattr(obj, method_name, None)
        if method is None or not callable(method):
            raise AttributeError(f"The object has no callable method named '{method_name}'.")

        # Call the method
        return py_call_w_args(method, *new_args)

    # ==================================================
    # CASE 5: Generic Callable
    # ==================================================
    # If none of the above patterns matched, but 'callable_obj' is indeed callable,
    # we just pass everything to py_call_w_args. This covers the scenario of built-in
    if len(args) > 0 and callable(callable_obj) and isinstance(args[0], object):
        instance = args[0]
        method_args = args[1:]

        # Bind the method to the instance and call it
        return py_call_w_args(callable_obj, *method_args)

    # ==================================================
    # CASE 6: Direct Callable Execution
    # ==================================================
    if callable(callable_obj):
        return py_call_w_args(callable_obj, *args)

    # ==================================================
    # CASE 7: If none matched, raise an error
    # ==================================================
    raise TypeError("The provided arguments do not form a callable invocation.")

def py_call_w_args(callable_obj, *w_args):
    """
    Calls a Python callable with the provided arguments, handling both positional
    and (optionally) keyword arguments. This function attempts to use inspect.signature
    to parse out how many positional vs. keyword parameters a function might expect.

    However, for built-in functions (like time.time) that do not have an inspectable
    signature, we catch the ValueError and fall back to a direct call with all arguments
    as positional.

    Args:
        callable_obj: The callable (function, bound method, unbound method, etc.) to be invoked.
        *w_args: Variable length argument list of parameters to be passed in some manner.

    Returns:
        The result of calling 'callable_obj' with the appropriate arguments.

    Raises:
        ValueError: If 'callable_obj' is not callable.
        TypeError: If there are missing or unexpected arguments based on the signature.
    """

    if not callable(callable_obj):
        raise ValueError("First argument must be callable.")

    args = list(w_args)
    kwargs = {}
    sig = inspect.signature(callable_obj)
    kwarg_names = {param.name for param in sig.parameters.values()
                   if param.kind in [param.KEYWORD_ONLY, param.VAR_KEYWORD]}

    method_args = []
    keyword_order_index = 0
    keyword_order = [name for name in sig.parameters if sig.parameters[name].kind == inspect.Parameter.KEYWORD_ONLY]

    for param in sig.parameters.values():
        if param.kind in [param.POSITIONAL_ONLY, param.POSITIONAL_OR_KEYWORD]:
            if args and not isinstance(args[0], (dict, list, tuple)):
                method_args.append(args.pop(0))
            elif param.default is inspect.Parameter.empty:
                raise TypeError(f"Missing required positional argument: '{param.name}'")
        elif param.kind == param.VAR_POSITIONAL:
            while args and not isinstance(args[0], (dict, list, tuple)):
                method_args.append(args.pop(0))
            break
        elif param.kind == param.KEYWORD_ONLY:
            if args and isinstance(args[0], (list, tuple)) and all(isinstance(x, (list, tuple)) for x in args[0]):
                # Handle a list or tuple of key-value pairs
                while args and isinstance(args[0], (list, tuple)):
                    pair = args.pop(0)
                    if pair[0] in kwarg_names:
                        kwargs[pair[0]] = pair[1]
                    else:
                        raise TypeError(f"Unexpected keyword argument: '{pair[0]}'")
            elif args and keyword_order_index < len(keyword_order):
                # Assume the next argument corresponds to the next keyword-only parameter by order
                kwargs[keyword_order[keyword_order_index]] = args.pop(0)
                keyword_order_index += 1
            else:
                raise TypeError(f"Expected keyword argument for '{keyword_order[keyword_order_index]}' not provided")

    # Handle remaining variadic keyword arguments
    if args:
        for arg in args:
            if isinstance(arg, dict):
                kwargs.update(arg)
            else:
                raise TypeError("Non-keyword arguments found after processing all parameters")

    # Debugging output
    if DEBUG_MODE:
        print("Debug Information:")
        print(f"Callable object: {callable_obj}")
        print(f"Positional arguments: {method_args}")
        print(f"Keyword arguments: {kwargs}")

    try:
        return callable_obj(*method_args, **kwargs)
    finally:
        flush_stdout_stderr()
    #
    # For now, let's omit that, or place it in a try/finally:
    #
    # (We'll keep it simple here.)



# Example usage
def wild_test_function(a, b, c=3, *args, d, **kwargs):
    print(f"a={a}, b={b}, c={c}, args={args}, d={d}, kwargs={kwargs}")

# Correct usage
def test_wild_test_function():
    py_call_method_and_args(test_function, 1, 2, 4, 5, d=6, e=7)


def py_call_method_and_args_kw(kwa, *method_and_args):
    """
    Calls a Python callable (function, method, or constructor) with the provided arguments.

    Handles various cases including:
    - Bound methods.
    - Function or method name as a string with an instance.
    - Class and method name as a string.
    - Object and method name as a string.
    - Unbound methods with an instance.
    - Other callable objects.

    Args:
        method_and_args: Variable length argument list.

    Returns:
        The result of the callable invocation.

    Raises:
        ValueError: If no callable is provided.
        TypeError: If the callable cannot be invoked.
        AttributeError: If the method does not exist on the given class or instance.
    """

    if DEBUG_MODE:
        print("Debug: Initial method_and_args =", method_and_args)
        print("Debug: Initial kwa =", kwa)

    # Check if a single argument is provided and if it is a list or tuple
    if len(method_and_args) == 1 and isinstance(method_and_args[0], (list, tuple)):
        method_and_args = method_and_args[0]
        if DEBUG_MODE:
            print("Debug: Unpacked method_and_args =", method_and_args)

    kwargs = kwa


    # Ensure there is at least one element to extract the callable
    if not method_and_args:
        raise ValueError("No callable provided to invoke.")

    callable_obj, *args = list(method_and_args)

    # Debug after extracting callable and args
    if DEBUG_MODE:
        print("Debug: Callable object =", callable_obj)
        print("Debug: Positional arguments =", args)

    # Case 1: Bound method
    if callable(callable_obj) and hasattr(callable_obj, '__self__') and callable_obj.__self__ is not None:
        # Call the bound method with the arguments
        return py_call_kw_args(kwargs,  callable_obj, *args)

    # Case 2: Function or method name as a string with an instance
    if isinstance(callable_obj, str) and len(args) > 0 and isinstance(args[0], object):
        method_name = callable_obj
        instance = args[0]
        method_args = args[1:]

        # Attempt to retrieve the method from the instance
        method = getattr(instance, method_name, None)
        if method is None or not callable(method):
            raise AttributeError(f"The instance has no callable method named '{method_name}'.")

        # Call the method with the arguments
        return py_call_kw_args(kwargs,  method, *method_args)

    # Case 3: Class and method name as a string
    if isinstance(callable_obj, type) and len(args) > 0 and isinstance(args[0], str):
        cls = callable_obj
        method_name = args[0]
        method_args = args[1:]

        # Attempt to retrieve the method from the class
        method = getattr(cls, method_name, None)
        if method is None or not callable(method):
            raise AttributeError(f"The class '{cls.__name__}' has no callable method named '{method_name}'.")

        # Call the method with the arguments
        return py_call_kw_args(kwargs, method, *method_args)

    # Case 4: Object and method name as a string
    if len(method_and_args) > 1 and isinstance(method_and_args[0], object) and isinstance(method_and_args[1], str):
        obj = method_and_args[0]
        method_name = method_and_args[1]
        args = method_and_args[2:]

        # Retrieve the method from the object
        method = getattr(obj, method_name, None)
        if method is None or not callable(method):
            raise AttributeError(f"The object has no callable method named '{method_name}'.")

        # Call the method with the arguments
        return py_call_kw_args(kwargs, method, *args)

    # Case 5: Unbound method (function) with an instance
    if len(args) > 0 and callable(callable_obj) and isinstance(args[0], object):
        instance = args[0]
        method_args = args[1:]

        # Bind the method to the instance and call it
        return py_call_kw_args(kwargs, callable_obj, *method_args)

    # Case 6: Other callable objects
    if callable(callable_obj):
        return py_call_kw_args(kwargs, callable_obj, *args)

    # If none of the above, raise an error
    raise TypeError("The provided arguments do not form a callable invocation.")

import inspect


def py_call_kw_args(kwargs, callable_obj, *w_args):
    """
    Calls a callable object with positional and keyword arguments,
    ensuring compatibility with its signature.

    :param kwargs: Dictionary of keyword arguments.
    :param callable_obj: The callable object to be invoked.
    :param w_args: Additional positional arguments.
    :return: The result of invoking the callable object.
    :raises ValueError: If the first argument is not callable.
    """
    if not callable(callable_obj):
        raise ValueError("First argument must be callable.")

    args = list(w_args)  # Positional arguments
    sig = inspect.signature(callable_obj)

    # Separate the expected keyword arguments from the function signature
    kwarg_names = {param.name for param in sig.parameters.values()
                   if param.kind in [inspect.Parameter.KEYWORD_ONLY, inspect.Parameter.VAR_KEYWORD]}

    # Prepare arguments for the callable
    method_args = []
    method_kwargs = {}

    # Positional arguments from the signature
    for i, (name, param) in enumerate(sig.parameters.items()):
        if param.kind == inspect.Parameter.POSITIONAL_OR_KEYWORD:
            if i < len(args):
                method_args.append(args[i])
            elif name in kwargs:
                method_args.append(kwargs.pop(name))
            elif param.default is not param.empty:
                method_args.append(param.default)
            else:
                raise TypeError(f"Missing required positional argument: \'{name}\'")

    # Handle *args (VAR_POSITIONAL)
    for param in sig.parameters.values():
        if param.kind == inspect.Parameter.VAR_POSITIONAL:
            remaining_args = args[len(method_args):]  # Extract remaining arguments
            method_args.extend(remaining_args)
            break

    # Handle keyword-only arguments
    for name, param in sig.parameters.items():
        if param.kind == inspect.Parameter.KEYWORD_ONLY:
            if name in kwargs:
                method_kwargs[name] = kwargs.pop(name)
            elif param.default is not param.empty:
                method_kwargs[name] = param.default
            else:
                raise TypeError(f"Missing required keyword-only argument: \'{name}\'")

    # Handle **kwargs if present in the signature
    if any(param.kind == inspect.Parameter.VAR_KEYWORD for param in sig.parameters.values()):
        method_kwargs.update(kwargs)
    elif kwargs:
        # If the function does not accept **kwargs and extras are provided
        raise TypeError(f"Got unexpected keyword arguments: {', '.join(kwargs.keys())}")

    # Debugging output
    if DEBUG_MODE:
        print("Debug Information:")
        print(f"Callable object: {callable_obj}")
        print(f"Positional arguments: {method_args}")
        print(f"Keyword arguments: {method_kwargs}")

    # Call the function with the prepared arguments
    try:
        return callable_obj(*method_args, **method_kwargs)
    finally:
        flush_stdout_stderr()



import importlib
import types
from types import MethodType

def make_py_dot_callable(target, method):
    return make_py_dot_bool(target, method, alwaysReturnAsCallable=True)

def make_py_dot(target, method):
    return make_py_dot_bool(target, method, alwaysReturnAsCallable=False)

def make_py_dot_bool(target, method, alwaysReturnAsCallable=False):
    """
    Returns a callable that dynamically invokes a method or function based on the provided target and method.

    Args:
        target (str or module or type or object): The module name, module object, class name, class object, or instance.
        method (str or callable): The method name as a string (supports dot-separated paths) or an already resolved callable.
        alwaysReturnAsCallable (bool): If True, wraps non-callable attributes into a callable that returns the attribute.

    Returns:
        callable: A function that takes any arguments and keyword arguments, and calls the specified method or function.
        If alwaysReturnAsCallable is True, non-callable attributes are wrapped in a callable.

    Raises:
        ImportError: If the specified module cannot be imported.
        AttributeError: If the specified method does not exist.
        TypeError: If the specified method is not callable and alwaysReturnAsCallable is False.
    """
    # If the method is already a callable, bind it to the target if required
    if callable(method):
        # Check if the target is required for the callable (e.g., unbound instance method)
        if isinstance(method, MethodType) and method.__self__ is None and isinstance(target, object):
            # Bind the method to the target
            return MethodType(method, target)
        # Otherwise, return the method as-is
        return method

    # If the method is not a string or callable, raise an error
    if not isinstance(method, str):
        raise TypeError(f"The method should be a string or callable, got {type(method)} instead.")

   # Resolve the target if it is a string (assumed to be a module or class name)
    if isinstance(target, str):
        # search the string type for the method name
        str_callable = getattr(target, method, None)
        if str_callable is not None:
          return str_callable
        try:
            resolved_target = make_py_atom(target)
            if resolved_target is not None:
                target = resolved_target
        except ValueError:
            resolved_target = None

        # If not resolved by make_py_atom, try importing it as a module
        if resolved_target is None:
            try:
                target = importlib.import_module(target)
            except ImportError:
                try:
                    # Attempt to import the class from the module path
                    module_name, class_name = target.rsplit(".", 1)
                    module = importlib.import_module(module_name)
                    target = getattr(module, class_name)
                except (ImportError, ValueError, AttributeError) as e:
                    raise ImportError(f"Could not import '{target}'. Ensure it is a valid module or class name.") from e

    attr = getattr(target, method, None)
    if attr is not None:
      return attr

    # If the target is a module, class, or instance, resolve the method
    if isinstance(target, (types.ModuleType, type, object)):

        try:
            # Resolve dot-separated method paths
            for attr in method.split("."):
                target = getattr(target, attr)
        except AttributeError as e:
            raise AttributeError(f"'{target}' has no attribute '{method}' or part of the method path could not be resolved.") from e

        # If the resolved attribute is not callable and alwaysReturnAsCallable is True, wrap it
        if not callable(target):
            if alwaysReturnAsCallable:
                def callable_function(*args, **kwargs):
                    return target
                return callable_function
            else:
                raise TypeError(f"The attribute '{method}' of '{target}' is not callable.")

        # If the target is an instance and the resolved method requires self, bind it
        if isinstance(target, MethodType) and hasattr(target, "__self__") and target.__self__ is None:
            # Bind the method to the instance
            bound_method = MethodType(target, target.__self__)
            def callable_function(*args, **kwargs):
                return bound_method(*args, **kwargs)
            return callable_function

        # Return a callable that invokes the resolved function with provided arguments
        def callable_function(*args, **kwargs):
            return target(*args, **kwargs)

        return callable_function

    raise TypeError(f"Unsupported target type: {type(target)}. Expected module, class, or instance.")


import importlib

def make_py_atom(target):
    """
    Resolves and returns a dynamic object, module, or expression result based on the provided target.
    Supports multi-dot paths for resolving nested attributes or methods.

    Args:
        target (str or object): The object, module name, fully qualified name, or expression to resolve.

    Returns:
        object: The resolved object, module, or expression result.

    Raises:
        ValueError: If the string cannot be evaluated, resolved, or imported.
    """
    # If the target is not a string, return it as is
    if not isinstance(target, str):
        return target

    # First, attempt to evaluate the string as a Python expression
    try:
        result = eval_string(target)
        return result
    except Exception:
        result = target # pass  # Ignore eval failure, proceed to other cases

    # If eval fails, try to resolve it as a module or a multi-dot attribute path
    try:
        # Split the target by dots and attempt to resolve recursively
        parts = target.split(".")
        module_name = parts[0]
        resolved = importlib.import_module(module_name)  # Start with the first part as a module
        for attr in parts[1:]:
            resolved = getattr(resolved, attr)  # Resolve nested attributes
        return resolved
    except (ImportError, AttributeError) as e:
        pass  # Not a fully qualified name, proceed to eval fallback

    # If all else fails, raise an error
    raise ValueError(f"Could not resolve '{target}'. Ensure it is a valid object, module, or expression.")

import sys

def flush_stdout_stderr():
    """
    Flushes both stdout and stderr to ensure all pending output is written immediately.

    This function checks if stdout and stderr are not None before attempting to flush them,
    and safely ignores any errors that occur during flushing. This provides a robust
    flushing operation in various environments where these streams might be redirected or
    could potentially raise exceptions when being flushed (e.g., if they have been closed).
    """
    try:
        if sys.stdout is not None:
            sys.stdout.flush()
    except Exception as e:
        # Optionally log or handle the specific exception here if needed
        pass  # Ignoring any error occurred during stdout flush

    try:
        if sys.stderr is not None:
            sys.stderr.flush()
    except Exception as e:
        # Optionally log or handle the specific exception here if needed
        pass  # Ignoring any error occurred during stderr flush

import io
import sys

def py_to_str(arg):
    captured_output = io.StringIO()  # Create a StringIO object to capture output
    sys.stdout = captured_output    # Redirect standard output to StringIO
    try:
        print(arg, end='')                  # Call print with the argument
    finally:
        sys.stdout = sys.__stdout__  # Restore standard output
    return captured_output.getvalue()  # Get the captured output as a string


the_modules_and_globals = merge_modules_and_globals()

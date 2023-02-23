// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TodoList {
    struct Todo {
        string text;
        bool status;
    }

    Todo[] private todos;

    function create(string calldata text_) public {
        todos.push(Todo(text_, false));
    }

    function updateText(uint256 index_, string calldata newText_) public {
        todos[index_].text = newText_;
    }

    function get(uint256 index_) public view returns (Todo memory) {
        return todos[index_];
    }

    function updateStatus(uint256 index_, bool status_) public {
        todos[index_].status = status_;
    }
}

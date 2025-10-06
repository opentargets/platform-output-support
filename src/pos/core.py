from otter import Runner


def main() -> None:
    runner = Runner('pos')
    runner.start()
    runner.register_tasks('pos.tasks')
    runner.run()

from crewai import Agent, Crew, Process, Task
from crewai.project import CrewBase, agent, crew, task

@CrewBase
class TerraforgeTeam:
    agents_config = "config/agents.yaml"
    tasks_config = "config/tasks.yaml"

    @agent
    def cto(self) -> Agent:
        return Agent(config=self.agents_config["cto"], verbose=True)
    @agent
    def engineer(self) -> Agent:
        return Agent(config=self.agents_config["engineer"], verbose=True)
    @agent
    def cloud_architect(self) -> Agent:
        return Agent(config=self.agents_config["cloud_architect"], verbose=True)
    @agent
    def security_lead(self) -> Agent:
        return Agent(config=self.agents_config["security_lead"], verbose=True)
    @agent
    def pm(self) -> Agent:
        return Agent(config=self.agents_config["pm"], verbose=True)
    @agent
    def sales_business(self) -> Agent:
        return Agent(config=self.agents_config["sales_business"], verbose=True)
    @agent
    def marketing(self) -> Agent:
        return Agent(config=self.agents_config["marketing"], verbose=True)

    @task
    def architecture_review(self) -> Task:
        return Task(config=self.tasks_config["architecture_review"])
    @task
    def write_code(self) -> Task:
        return Task(config=self.tasks_config["write_code"])
    @task
    def design_module(self) -> Task:
        return Task(config=self.tasks_config["design_module"])
    @task
    def security_review(self) -> Task:
        return Task(config=self.tasks_config["security_review"])
    @task
    def sprint_planning(self) -> Task:
        return Task(config=self.tasks_config["sprint_planning"])
    @task
    def market_analysis(self) -> Task:
        return Task(config=self.tasks_config["market_analysis"])
    @task
    def create_content(self) -> Task:
        return Task(config=self.tasks_config["create_content"])

    @crew
    def full_review(self) -> Crew:
        return Crew(
            agents=[self.cto(), self.engineer(), self.cloud_architect(),
                    self.security_lead(), self.pm(), self.sales_business(), self.marketing()],
            tasks=[self.architecture_review(), self.market_analysis(), self.sprint_planning()],
            process=Process.sequential, verbose=True)
    @crew
    def build(self) -> Crew:
        return Crew(
            agents=[self.cto(), self.engineer(), self.security_lead()],
            tasks=[self.architecture_review(), self.write_code(), self.security_review()],
            process=Process.sequential, verbose=True)
    @crew
    def plan(self) -> Crew:
        return Crew(
            agents=[self.pm(), self.cto()],
            tasks=[self.sprint_planning()],
            process=Process.sequential, verbose=True)
    @crew
    def business(self) -> Crew:
        return Crew(
            agents=[self.sales_business(), self.marketing()],
            tasks=[self.market_analysis(), self.create_content()],
            process=Process.sequential, verbose=True)
